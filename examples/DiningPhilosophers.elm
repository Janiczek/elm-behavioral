module DiningPhilosophers exposing (main)

import BProgram
import BThread exposing (BThread)


type Event
    = Phil1PickLeftFork
    | Phil1PickRightFork
    | Phil1DropLeftFork
    | Phil1DropRightFork
    | Phil2PickLeftFork
    | Phil2PickRightFork
    | Phil2DropLeftFork
    | Phil2DropRightFork
    | Phil3PickLeftFork
    | Phil3PickRightFork
    | Phil3DropLeftFork
    | Phil3DropRightFork


philosopher1 : BThread Event Event
philosopher1 =
    BThread.once "philosopher 1"
        [ BThread.blockAllWhileRequesting
            { request = Phil1PickLeftFork
            , block = [ Phil1PickRightFork, Phil1DropLeftFork, Phil1DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil1PickRightFork
            , block = [ Phil1PickLeftFork, Phil1DropLeftFork, Phil1DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil1DropLeftFork
            , block = [ Phil1PickLeftFork, Phil1PickRightFork, Phil1DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil1DropRightFork
            , block = [ Phil1PickLeftFork, Phil1PickRightFork, Phil1DropLeftFork ]
            }
        ]


philosopher2 : BThread Event Event
philosopher2 =
    BThread.once "philosopher 2"
        [ BThread.blockAllWhileRequesting
            { request = Phil2PickLeftFork
            , block = [ Phil2PickRightFork, Phil2DropLeftFork, Phil2DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil2PickRightFork
            , block = [ Phil2PickLeftFork, Phil2DropLeftFork, Phil2DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil2DropLeftFork
            , block = [ Phil2PickLeftFork, Phil2PickRightFork, Phil2DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil2DropRightFork
            , block = [ Phil2PickLeftFork, Phil2PickRightFork, Phil2DropLeftFork ]
            }
        ]


philosopher3 : BThread Event Event
philosopher3 =
    BThread.once "philosopher 3"
        [ BThread.blockAllWhileRequesting
            { request = Phil3PickLeftFork
            , block = [ Phil3PickRightFork, Phil3DropLeftFork, Phil3DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil3PickRightFork
            , block = [ Phil3PickLeftFork, Phil3DropLeftFork, Phil3DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil3DropLeftFork
            , block = [ Phil3PickLeftFork, Phil3PickRightFork, Phil3DropRightFork ]
            }
        , BThread.blockAllWhileRequesting
            { request = Phil3DropRightFork
            , block = [ Phil3PickLeftFork, Phil3PickRightFork, Phil3DropLeftFork ]
            }
        ]


fork1 : BThread Event Event
fork1 =
    BThread.forever "fork 1"
        [ BThread.blockAllUntilOneOf
            { block = [ Phil1DropLeftFork, Phil2DropRightFork ]
            , until = [ Phil1PickLeftFork, Phil2PickRightFork ]
            }
        , BThread.blockAllUntilOneOf
            { block = [ Phil1PickLeftFork, Phil2PickRightFork ]
            , until = [ Phil1DropLeftFork, Phil2DropRightFork ]
            }
        ]


fork2 : BThread Event Event
fork2 =
    BThread.forever "fork 2"
        [ BThread.blockAllUntilOneOf
            { block = [ Phil2DropLeftFork, Phil3DropRightFork ]
            , until = [ Phil2PickLeftFork, Phil3PickRightFork ]
            }
        , BThread.blockAllUntilOneOf
            { block = [ Phil2PickLeftFork, Phil3PickRightFork ]
            , until = [ Phil2DropLeftFork, Phil3DropRightFork ]
            }
        ]


fork3 : BThread Event Event
fork3 =
    BThread.forever "fork 3"
        [ BThread.blockAllUntilOneOf
            { block = [ Phil3DropLeftFork, Phil1DropRightFork ]
            , until = [ Phil3PickLeftFork, Phil1PickRightFork ]
            }
        , BThread.blockAllUntilOneOf
            { block = [ Phil3PickLeftFork, Phil1PickRightFork ]
            , until = [ Phil3DropLeftFork, Phil1DropRightFork ]
            }
        ]


main : Program () (BProgram.Model () Event Event) (BProgram.Msg Event Event)
main =
    BProgram.worker
        { bThreads =
            [ philosopher1
            , philosopher2
            , philosopher3
            , fork1
            , fork2
            , fork3
            ]
        , eventEmittedMsg = identity
        , toType = identity
        , init = \config () -> ( (), Cmd.none )
        , update =
            \config event () ->
                let
                    _ =
                        Debug.log "event" event
                in
                ( (), Cmd.none )
        , subscriptions = always Sub.none
        }
