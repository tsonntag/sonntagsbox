module Utils exposing (..)


import Html exposing (..)
import Html.Attributes exposing (..)
import Process exposing (sleep)
import Task exposing (perform)

boolToString : Bool -> String
boolToString   bool = if bool then "true" else "false"


viewInt : Maybe Int -> String
viewInt int = int |> Maybe.map String.fromInt |> Maybe.withDefault ""

after : Int -> msg -> Cmd msg
after time msg =
    Process.sleep (toFloat time) |> Task.perform (always msg)


propertiesTable : List (Html msg, Html msg) -> Html msg
propertiesTable props =
    table []
      (List.map (\( key, val) ->
                     tr []
                     [ td [ style "padding-right" "20px"] [ key ]
                     , td [] [ val ]
                     ])
            props)
