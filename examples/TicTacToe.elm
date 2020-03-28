module TicTacToe exposing (main)

{-| Not finished!!!
-}

import BProgram
import BThread exposing (BThread)
import Process
import Task


type Event
    = InsertX Int
    | InsertO Int
    | XWins
    | OWins
    | ItsADraw


type EventType
    = InsertX_
    | InsertO_
    | XWins_
    | OWins_
    | ItsADraw_


type alias Model =
    { log : List Event }


type Msg
    = -- and some other Msgs if we wanted to
      EventEmitted Event


xoCoord : Event -> Maybe Int
xoCoord event =
    case event of
        InsertX coord ->
            Just coord

        InsertO coord ->
            Just coord

        XWins ->
            Nothing

        OWins ->
            Nothing

        ItsADraw ->
            Nothing


toType : Event -> EventType
toType event =
    case event of
        InsertX _ ->
            InsertX_

        InsertO _ ->
            InsertO_

        XWins ->
            XWins_

        OWins ->
            OWins_

        ItsADraw ->
            ItsADraw_


ofType : EventType -> Event -> Bool
ofType type_ event =
    type_ == toType event


ofTypes : List EventType -> Event -> Bool
ofTypes types event =
    List.any (\t -> ofType t event) types


enforceTurns : BThread Event EventType
enforceTurns =
    BThread.forever "enforce turns"
        [ BThread.blockUntil { block = InsertX_, until = InsertO_ }
        , BThread.blockUntil { block = InsertO_, until = InsertX_ }
        ]


disallowSquareReuse_ : Int -> BThread Event EventType
disallowSquareReuse_ coord =
    let
        pred event =
            ofTypes [ InsertX_, InsertO_ ] event && xoCoord event == Just coord
    in
    BThread.once ("disallow square reuse at coord " ++ String.fromInt coord)
        [ BThread.waitForFn pred
        , BThread.blockFn pred
        ]


disallowSquareReuse : List (BThread Event EventType)
disallowSquareReuse =
    List.range 0 8
        |> List.map disallowSquareReuse_


detectDraw : BThread Event EventType
detectDraw =
    let
        oneMoveWait =
            BThread.waitForOneOf [ InsertX_, InsertO_ ]
    in
    BThread.once "detect draw"
        [ oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , oneMoveWait
        , BThread.request ItsADraw
        ]


stopGameAfterWin : BThread Event EventType
stopGameAfterWin =
    BThread.once "stop game after win"
        [ BThread.waitForOneOf [ XWins_, OWins_ ]
        , BThread.blockAll [ InsertX_, InsertO_ ]
        ]


computerMoves : BThread Event EventType
computerMoves =
    BThread.forever "computer moves"
        [ List.range 0 8
            |> List.map InsertO
            |> BThread.requestAnyOf
        ]


computerStartsAtCenter : BThread Event EventType
computerStartsAtCenter =
    BThread.once "computer starts at center"
        [ BThread.request (InsertO 4) ]


detectWin : Event -> (Int -> Event) -> List (BThread Event EventType)
detectWin winEvent insertEvent =
    -- horizontals
    [ ( 0, 1, 2 )
    , ( 3, 4, 5 )
    , ( 6, 7, 8 )

    -- verticals
    , ( 0, 3, 6 )
    , ( 1, 4, 7 )
    , ( 2, 5, 8 )

    -- diagonals
    , ( 0, 4, 8 )
    , ( 2, 4, 6 )
    ]
        |> List.map
            (\( i0, i1, i2 ) ->
                let
                    moves =
                        [ insertEvent i0, insertEvent i1, insertEvent i2 ]

                    oneMoveWait =
                        BThread.waitForFn (\e -> List.member e moves)
                in
                BThread.once ("detect " ++ Debug.toString winEvent ++ " using indices " ++ Debug.toString ( i0, i1, i2 ))
                    [ oneMoveWait
                    , oneMoveWait
                    , oneMoveWait
                    , BThread.request winEvent
                    ]
            )


main : Program () (BProgram.Model Model Event EventType) (BProgram.Msg Msg Event)
main =
    BProgram.worker
        { bThreads =
            [ enforceTurns
            , stopGameAfterWin

            {- Order matters! this has to be before computerMoves. Priorities as
               seen in more advanced BP implementations would also solve this...
            -}
            , computerStartsAtCenter
            , computerMoves
            , detectDraw

            -- TODO more advanced AI than just trying moves in order:
            -- , preventLineWithTwo
            -- , completeLineWithTwo
            -- , interceptSingleFork
            -- , interceptDoubleFork
            ]
                ++ detectWin XWins InsertX
                ++ detectWin OWins InsertO
                ++ disallowSquareReuse
        , eventEmittedMsg = EventEmitted
        , toType = toType
        , init =
            \config () ->
                let
                    emitAt : ( Float, Event ) -> Cmd (BProgram.Msg Msg Event)
                    emitAt ( milliseconds, event ) =
                        Process.sleep milliseconds
                            |> Task.perform (always (config.requestEvent event))
                in
                -- simulating user clicks in absence of HTML UI
                ( { log = [] }
                , [ ( 1000, InsertX 0 )
                  , ( 2000, InsertX 1 )
                  , ( 3000, InsertX 2 )
                  , ( 4000, InsertX 3 )
                  , ( 5000, InsertX 4 )
                  , ( 6000, InsertX 5 )
                  , ( 7000, InsertX 6 )
                  , ( 8000, InsertX 7 )
                  , ( 9000, InsertX 8 )
                  ]
                    |> List.map emitAt
                    |> Cmd.batch
                )
        , update =
            \config msg model ->
                case msg of
                    EventEmitted event ->
                        let
                            _ =
                                Debug.log "Main got EventEmitted" event
                        in
                        ( { model | log = model.log ++ [ event ] }
                          -- TODO ++ -> :: somehow?
                        , Cmd.none
                        )
        , subscriptions = always Sub.none
        }
