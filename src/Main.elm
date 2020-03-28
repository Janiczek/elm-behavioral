module Main exposing (main)

import BProgram
import BThread exposing (BThread)
import Process
import Task


type Event
    = InsertX Int
    | InsertO Int
    | XWins
    | OWins


type EventType
    = InsertX_
    | InsertO_
    | XWins_
    | OWins_


type alias Model =
    { log : List Event }


type Msg
    = -- and some other Msgs if we wanted to
      EventEmitted Event


main : Program () (BProgram.Model Model Event EventType) (BProgram.Msg Msg Event)
main =
    BProgram.worker
        { bThreads =
            [ enforceTurns

            --, disallowSquareReuse
            , stopGameAfterWin
            , computerStartsAtCenter -- order matters!

            --, computerMoves
            ]
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
                ( { log = [] }
                , [ ( 1000, InsertX 1 )
                  , ( 2000, InsertX 2 )
                  , ( 3000, InsertX 3 )
                  , ( 4000, InsertX 4 )
                  , ( 5000, InsertX 5 )
                  , ( 6000, InsertX 6 )
                  , ( 7000, InsertX 7 )
                  , ( 8000, InsertX 8 )
                  , ( 9000, InsertX 9 )
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



--disallowSquareReuse_ : Int -> BThread Event EventType
--disallowSquareReuse_ coord =
--    let
--        pred event =
--            ofTypes [ InsertX_, InsertO_ ] event && xoCoord event == Just coord
--    in
--    BThread.once ("disallow square reuse at coord " ++ String.fromInt coord)
--        [ BThread.waitForFn pred
--        , BThread.blockFn pred
--        ]
--disallowSquareReuse : BThread Event EventType
--disallowSquareReuse =
--    List.range 0 8
--        |> List.map disallowSquareReuse_
--        |> BThread.multiple


stopGameAfterWin : BThread Event EventType
stopGameAfterWin =
    BThread.once "stop game after win"
        [ BThread.waitForOneOf [ XWins_, OWins_ ]
        , BThread.blockAll [ InsertX_, InsertO_ ]
        ]



--computerMoves : BThread Event EventType
--computerMoves =
--    BThread.forever "computer moves"
--        [ List.range 0 8
--            |> List.map InsertO
--            |> BThread.requestFirstApplicableOf
--        ]


computerStartsAtCenter : BThread Event EventType
computerStartsAtCenter =
    BThread.once "computer starts at center"
        [ BThread.request (InsertO 4) ]
