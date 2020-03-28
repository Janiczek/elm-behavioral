module BThread.Internal exposing
    ( BCmd(..)
    , BThread
    , BThreadId
    , BThreadState(..)
    , BThreadType(..)
    , cmdToState
    , notifyOf
    )

import List.Zipper as Zipper exposing (Zipper)


type alias BThread e et =
    { state : BThreadState e
    , type_ : BThreadType
    , cmds : Zipper (BCmd e et)
    , id : BThreadId
    , label : String
    }


type alias BThreadId =
    Int


type BThreadState e
    = Requesting e
    | RequestingAnyOf (List e)
    | WaitingFor (e -> Bool)
    | Blocking (e -> Bool)
    | BlockingUntil {- wait + block -} { blocking : e -> Bool, until : e -> Bool }
    | BlockingWhileRequesting {- request + block -} { blocking : e -> Bool, requesting : e }
    | NoCmdSuppliedError


type BThreadType
    = RepeatForever
    | RepeatNTimes Int
    | Finished


type BCmd e et
    = Request e
    | RequestAnyOf (List e)
    | WaitFor et
    | WaitForFn (e -> Bool)
    | WaitForOneOf (List et)
    | WaitForOneOfFn (List (e -> Bool))
    | Block et
    | BlockFn (e -> Bool)
    | BlockAll (List et)
    | BlockAllFn (List (e -> Bool))
    | BlockAllWhileRequesting { block : List et, request : e }
    | BlockUntil { block : et, until : et }
    | BlockUntilFn { block : e -> Bool, until : e -> Bool }
    | BlockAllUntilOneOf { block : List et, until : List et }
    | NoCmdSupplied


cmdToState : (e -> et) -> BCmd e et -> BThreadState e
cmdToState toType cmd =
    let
        isOfType : et -> e -> Bool
        isOfType et e =
            toType e == et

        isOneOfTypes : List et -> e -> Bool
        isOneOfTypes ets e =
            List.member (toType e) ets

        isSatisfiedByOneOf : List (e -> Bool) -> e -> Bool
        isSatisfiedByOneOf preds e =
            List.any (\pred -> pred e) preds
    in
    case cmd of
        NoCmdSupplied ->
            NoCmdSuppliedError

        Request e ->
            Requesting e

        RequestAnyOf es ->
            RequestingAnyOf es

        WaitFor et ->
            WaitingFor (isOfType et)

        WaitForFn pred ->
            WaitingFor pred

        WaitForOneOf ets ->
            WaitingFor (isOneOfTypes ets)

        WaitForOneOfFn preds ->
            WaitingFor (isSatisfiedByOneOf preds)

        Block et ->
            Blocking (isOfType et)

        BlockFn pred ->
            Blocking pred

        BlockAll ets ->
            Blocking (isOneOfTypes ets)

        BlockAllFn preds ->
            Blocking (isSatisfiedByOneOf preds)

        BlockAllWhileRequesting { block, request } ->
            BlockingWhileRequesting
                { blocking = isOneOfTypes block
                , requesting = request
                }

        BlockUntil { block, until } ->
            BlockingUntil
                { blocking = isOfType block
                , until = isOfType until
                }

        BlockUntilFn { block, until } ->
            BlockingUntil
                { blocking = block
                , until = until
                }

        BlockAllUntilOneOf { block, until } ->
            BlockingUntil
                { blocking = isOneOfTypes block
                , until = isOneOfTypes until
                }


{-| Here we know we _can_ step, so we step unconditionally.
-}
stepUnconditionally : (e -> et) -> BThread e et -> BThread e et
stepUnconditionally toType bThread =
    let
        run () =
            let
                ( newType, newCmds ) =
                    -- Advance the bThread cmd zipper - point to the next cmd
                    Zipper.next bThread.cmds
                        |> Maybe.map
                            (\newCmds_ ->
                                ( bThread.type_
                                , newCmds_
                                )
                            )
                        |> Maybe.withDefault
                            {- In case we just ran the last cmd in the bThread,
                               we go back to the beginning and change the type,
                               eg. from RepeatNTimes 5 to RepeatNTimes 4 or
                               from RepeatNTimes 1 to Finished.
                            -}
                            ( decrement bThread.type_
                            , Zipper.first bThread.cmds
                            )

                newState =
                    cmdToState toType (Zipper.current newCmds)
            in
            { state = newState
            , type_ = newType
            , cmds = newCmds
            , id = bThread.id
            , label = bThread.label
            }
    in
    case bThread.state of
        NoCmdSuppliedError ->
            bThread

        Requesting _ ->
            run ()

        RequestingAnyOf _ ->
            run ()

        WaitingFor _ ->
            run ()

        Blocking _ ->
            run ()

        BlockingUntil _ ->
            run ()

        BlockingWhileRequesting _ ->
            run ()


decrement : BThreadType -> BThreadType
decrement type_ =
    case type_ of
        RepeatForever ->
            RepeatForever

        RepeatNTimes n ->
            if n <= 1 then
                Finished

            else
                RepeatNTimes (n - 1)

        Finished ->
            Finished


notifyOf : (e -> et) -> e -> BThread e et -> BThread e et
notifyOf toType selectedEvent bThread =
    case bThread.state of
        Requesting e ->
            if e == selectedEvent then
                stepUnconditionally toType bThread

            else
                bThread

        RequestingAnyOf es ->
            if List.member selectedEvent es then
                stepUnconditionally toType bThread

            else
                bThread

        WaitingFor pred ->
            if pred selectedEvent then
                stepUnconditionally toType bThread

            else
                bThread

        Blocking _ ->
            bThread

        BlockingUntil { until } ->
            if until selectedEvent then
                stepUnconditionally toType bThread

            else
                bThread

        BlockingWhileRequesting { requesting } ->
            if requesting == selectedEvent then
                stepUnconditionally toType bThread

            else
                bThread

        NoCmdSuppliedError ->
            bThread
