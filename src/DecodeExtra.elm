module DecodeExtra exposing (..)

import Json.Decode exposing (..)


listSafe : Decoder a -> Decoder (List a)
listSafe decoder =
    let
        catMaybes : List (Maybe a) -> List a
        catMaybes =
            List.filterMap identity
    in
    map catMaybes <| list (maybe decoder)
