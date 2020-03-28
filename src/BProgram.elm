module BProgram exposing
    ( Config
    , Model
    , Msg
    , worker
    )

-- TODO debugWorker
-- TODO element
-- TODO debugElement

import BThread.Internal as BThread
    exposing
        ( BThread
        , BThreadId
        , BThreadState(..)
        , BThreadType(..)
        )
import List.Zipper as Zipper
import Platform


type alias Model model e et =
    { userModel : model
    , bThreads : List (BThread e et)
    , userRequest : Maybe e
    }


type Msg msg e
    = UserMsg msg
    | EventRequested e


type alias WorkerApp flags model msg e et =
    { bThreads : List ((e -> et) -> BThreadId -> BThread e et)
    , eventEmittedMsg : e -> msg
    , toType : e -> et
    , init : Config msg e -> flags -> ( model, Cmd (Msg msg e) )
    , update : Config msg e -> msg -> model -> ( model, Cmd (Msg msg e) )
    , subscriptions : model -> Sub msg
    }


{-| So that user can request events from their `update`
-}
type alias Config msg e =
    { requestEvent : e -> Msg msg e
    , msg : msg -> Msg msg e
    }


config : Config msg e
config =
    { requestEvent = EventRequested
    , msg = UserMsg
    }


worker :
    WorkerApp flags model msg e et
    -> Program flags (Model model e et) (Msg msg e)
worker app =
    Platform.worker
        { init = init app
        , update = update app
        , subscriptions = subscriptions app.subscriptions
        }


subscriptions :
    (model -> Sub msg)
    -> Model model e et
    -> Sub (Msg msg e)
subscriptions userSubscriptions model =
    userSubscriptions model.userModel
        |> Sub.map UserMsg


init :
    WorkerApp flags model msg e et
    -> flags
    -> ( Model model e et, Cmd (Msg msg e) )
init app flags =
    let
        ( userModel, cmd ) =
            app.init config flags
    in
    ( { userModel = userModel
      , bThreads =
            app.bThreads
                |> List.indexedMap (\id toThread -> toThread app.toType id)
      , userRequest = Nothing
      }
    , cmd
    )
        |> sync app


type alias Snapshot e =
    { requests : List ( String, BThreadId, e )
    , waits : List ( String, BThreadId, e -> Bool )
    , blocks : List ( String, BThreadId, e -> Bool )
    }


toSnapshot : Model model e et -> Snapshot e
toSnapshot model =
    List.foldl
        (\bThread accSnapshot ->
            if bThread.type_ == Finished then
                accSnapshot

            else
                case bThread.state of
                    Requesting e ->
                        accSnapshot
                            |> addRequest bThread.label bThread.id e

                    RequestingAnyOf es ->
                        List.foldl
                            (addRequest bThread.label bThread.id)
                            accSnapshot
                            es

                    WaitingFor pred ->
                        accSnapshot
                            |> addWait bThread.label bThread.id pred

                    Blocking pred ->
                        accSnapshot
                            |> addBlock bThread.label bThread.id pred

                    BlockingUntil { blocking, until } ->
                        accSnapshot
                            |> addBlock bThread.label bThread.id blocking
                            |> addWait bThread.label bThread.id until

                    BlockingWhileRequesting { blocking, requesting } ->
                        accSnapshot
                            |> addBlock bThread.label bThread.id blocking
                            |> addRequest bThread.label bThread.id requesting

                    NoCmdSuppliedError ->
                        accSnapshot
        )
        (Snapshot [] [] []
            |> (model.userRequest
                    |> Maybe.map (addRequest "user request" -1)
                    |> Maybe.withDefault identity
               )
        )
        model.bThreads
        |> (\s -> { s | requests = List.reverse s.requests })


addRequest : String -> BThreadId -> e -> Snapshot e -> Snapshot e
addRequest label id e snapshot =
    { snapshot | requests = ( label, id, e ) :: snapshot.requests }


addWait : String -> BThreadId -> (e -> Bool) -> Snapshot e -> Snapshot e
addWait label id pred snapshot =
    { snapshot | waits = ( label, id, pred ) :: snapshot.waits }


addBlock : String -> BThreadId -> (e -> Bool) -> Snapshot e -> Snapshot e
addBlock label id pred snapshot =
    { snapshot | blocks = ( label, id, pred ) :: snapshot.blocks }


iterate : (a -> Maybe a) -> a -> a
iterate step value =
    case step value of
        Nothing ->
            value

        Just newValue ->
            iterate step newValue


sync :
    WorkerApp flags model msg e et
    -> ( Model model e et, Cmd (Msg msg e) )
    -> ( Model model e et, Cmd (Msg msg e) )
sync app modelAndCmd =
    iterate
        (\( model, cmd ) ->
            let
                snapshot : Snapshot e
                snapshot =
                    toSnapshot model

                okRequests : List e
                okRequests =
                    snapshot.requests
                        |> List.filterMap
                            (\( _, _, e ) ->
                                if not <| List.any (\( _, _, pred ) -> pred e) snapshot.blocks then
                                    Just e

                                else
                                    Nothing
                            )

                maybeSelectedEvent : Maybe e
                maybeSelectedEvent =
                    -- TODO priority?
                    List.head okRequests
            in
            maybeSelectedEvent
                |> Maybe.map
                    (\selectedEvent ->
                        emitEventWithSnapshot
                            selectedEvent
                            (toSnapshot model)
                            app
                            ( model, cmd )
                    )
        )
        modelAndCmd


emitEvent :
    e
    -> WorkerApp flags model msg e et
    -> ( Model model e et, Cmd (Msg msg e) )
    -> ( Model model e et, Cmd (Msg msg e) )
emitEvent selectedEvent app ( model, cmd ) =
    emitEventWithSnapshot
        selectedEvent
        (toSnapshot model)
        app
        ( model, cmd )


emitEventWithSnapshot :
    e
    -> Snapshot e
    -> WorkerApp flags model msg e et
    -> ( Model model e et, Cmd (Msg msg e) )
    -> ( Model model e et, Cmd (Msg msg e) )
emitEventWithSnapshot selectedEvent snapshot app ( model, cmd ) =
    let
        requestIdsToNotify : List ( String, BThreadId )
        requestIdsToNotify =
            snapshot.requests
                |> List.filterMap
                    (\( label, id, e ) ->
                        if e == selectedEvent then
                            Just ( label, id )

                        else
                            Nothing
                    )

        waitIdsToNotify : List ( String, BThreadId )
        waitIdsToNotify =
            snapshot.waits
                |> List.filterMap
                    (\( label, id, pred ) ->
                        if pred selectedEvent then
                            Just ( label, id )

                        else
                            Nothing
                    )

        bThreadIdsToNotify : List BThreadId
        bThreadIdsToNotify =
            (requestIdsToNotify ++ waitIdsToNotify)
                |> List.map Tuple.second

        modelAfterNotifying : Model model e et
        modelAfterNotifying =
            List.foldl
                (\bThreadId accModel ->
                    { accModel
                        | bThreads =
                            accModel.bThreads
                                |> List.map
                                    (\bThread ->
                                        if bThread.id == bThreadId then
                                            -- TODO so inefficient! refactor to rational db model
                                            BThread.notifyOf app.toType selectedEvent bThread

                                        else
                                            bThread
                                    )
                        , userRequest =
                            if bThreadId == -1 then
                                -- TODO use a custom type for this
                                Nothing

                            else
                                accModel.userRequest
                    }
                )
                model
                bThreadIdsToNotify

        ( newUserModel, newCmd ) =
            app.update
                config
                (app.eventEmittedMsg selectedEvent)
                modelAfterNotifying.userModel

        newModel =
            { modelAfterNotifying | userModel = newUserModel }
    in
    ( newModel
    , Cmd.batch [ cmd, newCmd ]
    )


update :
    WorkerApp flags model msg e et
    -> Msg msg e
    -> Model model e et
    -> ( Model model e et, Cmd (Msg msg e) )
update app msg model =
    case msg of
        UserMsg userMsg ->
            let
                ( newUserModel, userCmd ) =
                    app.update config userMsg model.userModel
            in
            ( { model | userModel = newUserModel }
            , userCmd
            )

        EventRequested event ->
            ( { model | userRequest = Just event }
            , Cmd.none
            )
                |> sync app
