module Koffein.Point exposing (..)

import Browser
import Html exposing (..)
import Html.Events exposing (..)
import Html.Attributes exposing (..)


type alias Point = { x: Int, y: Int }

drawPointText : Point -> Html msg
drawPointText { x, y } =
    div [] [ text "x="
           , text (String.fromInt x)
           , text "y="
           , text (String.fromInt y)
           ]

type Msg
    = Clicked

px p = (String.fromInt (p * 20)) ++ "px"

drawPoint : Point -> Html Msg
drawPoint { x, y } =
    button [ onClick Clicked
           , class "btn btn-danger"
           , style "width"  "20px"
           , style "height" "20px"
           , style "margin-left" (px x)
           , style "margin-top"  (px y)
           ]
    [ text "" ]

