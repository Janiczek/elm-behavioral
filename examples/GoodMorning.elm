module GoodMorning exposing (main)

import BProgram
import BThread exposing (BThread)


type Event
    = Morning
    | Evening


morning : BThread Event Event
morning =
    BThread.repeat 3
        "morning"
        [ BThread.request Morning ]


evening : BThread Event Event
evening =
    BThread.repeat 3
        "evening"
        [ BThread.request Evening ]


interleave : BThread Event Event
interleave =
    BThread.forever "interleave"
        [ BThread.blockUntil { block = Evening, until = Morning }
        , BThread.blockUntil { block = Morning, until = Evening }
        ]


main : Program () (BProgram.Model () Event Event) (BProgram.Msg Event Event)
main =
    BProgram.worker
        { bThreads =
            [ morning
            , evening
            , interleave
            ]
        , eventEmittedMsg = identity
        , toType = identity
        , init = \config () -> ( (), Cmd.none )
        , update =
            \config event () ->
                let
                    _ =
                        Debug.log "Good" event
                in
                ( (), Cmd.none )
        , subscriptions = always Sub.none
        }
