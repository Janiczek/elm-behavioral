module BThread exposing
    ( BThread, BCmd
    , once, repeat, forever
    , request
    , waitFor, waitForFn, waitForOneOf, waitForOneOfFn
    , block, blockFn, blockAll, blockUntil
    )

{-|


# Types

@docs BThread, BCmd


# BThread constructors

@docs once, repeat, forever


# BCmd constructors - Request

@docs request


# BCmd constructors - WaitFor

@docs waitFor, waitForFn, waitForOneOf, waitForOneOfFn


# BCmd constructors - Block

@docs block, blockFn, blockAll, blockUntil

-}

import BThread.Internal as Internal
    exposing
        ( BCmd(..)
        , BThreadId
        , BThreadState(..)
        , BThreadType(..)
        )
import List.Zipper as Zipper exposing (Zipper)


type alias BThread e et =
    (e -> et) -> BThreadId -> Internal.BThread e et


type alias BCmd e et =
    Internal.BCmd e et



-- BThread constructors


threadFromList : BThreadType -> String -> List (BCmd e et) -> (e -> et) -> BThreadId -> Internal.BThread e et
threadFromList type_ label cmds toType id =
    cmds
        |> Zipper.fromList
        |> Maybe.map
            (\zipper ->
                { state = Internal.cmdToState toType (Zipper.current zipper)
                , type_ = type_
                , cmds = zipper
                , id = id
                , label = label
                }
            )
        |> Maybe.withDefault
            { state = Internal.cmdToState toType NoCmdSupplied
            , type_ = type_
            , cmds = Zipper.singleton NoCmdSupplied
            , id = id
            , label = label
            }


once : String -> List (BCmd e et) -> BThread e et
once =
    threadFromList (RepeatNTimes 1)


repeat : Int -> String -> List (BCmd e et) -> BThread e et
repeat n =
    threadFromList (RepeatNTimes n)


forever : String -> List (BCmd e et) -> BThread e et
forever =
    threadFromList RepeatForever



-- BCmd constructors - Request


request : e -> BCmd e et
request =
    Request



-- BCmd constructors - WaitFor


waitFor : et -> BCmd e et
waitFor =
    WaitFor


waitForFn : (e -> Bool) -> BCmd e et
waitForFn =
    WaitForFn


waitForOneOf : List et -> BCmd e et
waitForOneOf =
    WaitForOneOf


waitForOneOfFn : List (e -> Bool) -> BCmd e et
waitForOneOfFn =
    WaitForOneOfFn



-- BCmd constructors - Block


block : et -> BCmd e et
block =
    Block


blockFn : (e -> Bool) -> BCmd e et
blockFn =
    BlockFn


blockAll : List et -> BCmd e et
blockAll =
    BlockAll


blockUntil : { block : et, until : et } -> BCmd e et
blockUntil =
    BlockUntil
