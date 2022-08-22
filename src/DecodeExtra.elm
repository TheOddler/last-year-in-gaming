module DecodeExtra exposing (..)

import Json.Decode exposing (..)
import Maybe.Extra exposing (values)


listSafe : Decoder a -> Decoder (List a)
listSafe decoder =
    map values <| list (maybe decoder)
