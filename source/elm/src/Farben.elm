module Farben exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (..)
import Debug exposing (log)
import Utils exposing (..)
import ItemLists exposing (data)
import Array exposing (..)

main =
  Browser.element
    { init = init , update = update , subscriptions = subscriptions , view = view}

type alias Item = ( Int, String, String )
type alias ItemList = List Item
type alias Model = { inputInterval : String
                   , interval      : Int
                   , inputFactor   : String
                   , factor        : Float
                   , item          : Maybe Item
                   , itemListIndex : Maybe Int
                   , itemList      : Maybe ItemList
                   , page          : Page
                   }
type Page
    = PrintOne
    | PrintAll
    | Game

itemLists : Array ItemList
itemLists = ItemLists.data |> Array.fromList

nItemLists : Int
nItemLists = Array.length itemLists

initialItemListIndex : Maybe Int
initialItemListIndex = if Array.isEmpty itemLists then Nothing else Just 0

initialModel : Model
initialModel =
    { itemListIndex = initialItemListIndex
    , itemList      = getItemList initialItemListIndex
    , item          = Nothing
    , inputInterval = "1500"
    , interval      = 1500
    , inputFactor   = "0.95"
    , factor        = 0.95
    , page          = Game
    }

resetModel : Maybe Int -> Model -> Model
resetModel itemListIndex model =
    { model |
      itemListIndex = itemListIndex
    , itemList      = getItemList itemListIndex
    , item          = Nothing
    }

type Msg
  = Start
  | NextItem
  | SetItemList String
  | SetInputInterval String
  | SetInputFactor String
  | SetPage Page

spy : String -> a -> a
spy info thing =
    Debug.log (info ++ (Debug.toString thing)) thing


nextCmd : Model -> Cmd Msg
nextCmd model = after model.interval NextItem


getItemList : Maybe Int -> Maybe ItemList
getItemList index =
    case index of
        Just i ->
            Array.get i itemLists
        _ ->
            Nothing


init : () -> (Model, Cmd Msg)
init _ = ( initialModel, Cmd.none )


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Start ->
            let
                factor   = model.inputFactor   |> String.toFloat |> Maybe.withDefault model.factor
                interval = model.inputInterval |> String.toInt   |> Maybe.withDefault model.interval
            in
                (
                 { model |
                   factor        = factor
                 , inputFactor   = factor |> String.fromFloat
                 , interval      = interval
                 , inputInterval = interval |> String.fromInt
                 , item          = model.itemListIndex |> getItemList |> Maybe.andThen List.head
                 }
                 |> resetModel model.itemListIndex

                , after 500 NextItem )

        NextItem ->
            case model.itemList of
                Just (item :: rest) ->
                    ( { model | interval = (toFloat model.interval) * model.factor |> ceiling,
                                item     = Just item |> spy "ITEM",
                                itemList = Just rest }
                    , nextCmd model
                    )

                _ ->
                    ( resetModel model.itemListIndex model
                    , Cmd.none )


        SetInputFactor val ->
            ( { model | inputFactor = val } , Cmd.none )

        SetInputInterval val ->
            ( { model | inputInterval = val } , Cmd.none )

        SetItemList val ->
            ( resetModel (String.toInt val) model, Cmd.none )

        SetPage page ->
            ( { model | page = page } , Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model = Sub.none


intToOption : Int ->Int -> Html Msg
intToOption selectedIndex i =
    option [ value (String.fromInt i)
           , selected (i == selectedIndex)
           ]
           [ text  (String.fromInt (i + 1))]


view : Model -> Html Msg
view model =
    case model.page of
        PrintOne ->
            printOneItemList model
        PrintAll ->
            printAllItemLists itemLists
        Game ->
            viewGame model

printItem : Item -> Html Msg
printItem ( i, name, color ) =
    li []
       [ h3 [ style "display" "inline-flex" ]
             [ div [ style "width" "50px"]
                   [ text <| (String.fromInt i) ++ "."]
             , div [] [ text <| translateColor color ]
             ]
       ]


printAllItemLists : Array ItemList  -> Html Msg
printAllItemLists lists =
    div [ class "container"]
        ([ div [ class "row mt-3" ]
               [ button [ onClick (SetPage Game) ] [ text "Zurück" ]]
         ]
         ++
         (lists |> Array.toList |> List.indexedMap
              (\i list ->
               div [] (doPrintItemList list i))
         )
        )

printOneItemList : Model -> Html Msg
printOneItemList model =
    case ( model.itemListIndex, model.itemList ) of
        ( Just i, Just l ) ->
            div [ class "container"]
                ([ div [ class "row mt-3" ]
                       [ button [ onClick (SetPage Game) ] [ text "Zurück" ]]
                 ]
                 ++
                 (doPrintItemList l i)
                )

        _ ->
            div []
                [ text "Keine Liste vorhanden"]

doPrintItemList: ItemList -> Int -> List (Html Msg)
doPrintItemList list i  =
    [ div [ class "row mt-5" ]
          [ h1 [] [ text ("Liste " ++ String.fromInt (i + 1)) ]]

    , div [ class "row mt-3" ]
        [ ul [ class "list-unstyled"]
              (List.map printItem list) ]
    ]


viewGame : Model -> Html Msg
viewGame model =
    div [ class "container"]
        [ case ( model.itemListIndex, model.itemList ) of
              ( Just index, Just list ) ->
                  viewBody model list index
              _ ->
                  div [] [ text "Keine Daten" ]
        ]

viewBody : Model -> ItemList -> Int -> Html Msg
viewBody model list index =
    div []
        [ div [ class "row mt-5" ]
            [ div   [ style "width" "100px"] [ text "Faktor:"]
            , input [ onInput SetInputFactor
                    , value model.inputFactor
                    ] []
            ]

        , div [ class "row mt-2" ]
            [ div   [ style "width" "100px"] [ text "Intervall:"]
            , input [ onInput SetInputInterval
                    , value model.inputInterval
                    ] []
--          , text (String.fromInt model.interval)
            ]
        , div [ class "row mt-3" ]
            [ div    [ style "width" "100px"] [ text "Liste:"]

            , select [ onInput SetItemList ]
                (List.map (intToOption index) (List.range 0 (nItemLists - 1)))

            , button [ onClick (SetPage PrintOne)
                     , class "ml-3"]
                     [ text "Zeige Liste" ]

            , button [ onClick (SetPage PrintAll)
                     , class "ml-3"]
                     [ text "Zeige alle Listen" ]
            ]
        , div [ class "row mt-2" ]
            [ div [ style "width" "100px"] [ text "Farben:"]
            , div [] [ text (Just index |> getItemList |> (Maybe.withDefault []) |> List.length |> String.fromInt)]
            ]

        , div [ class "row mt-4" ]
            [ button [ onClick Start ] [ text "Start" ]
            ]

        , div [ class "row mt-5" ]
            [ viewItem model.item
            ]
        ]

viewItem : Maybe Item -> Html Msg
viewItem item =
    case item of
        Nothing ->
            text ""
        Just ( i, text_, color )  ->
            h1 [ style "display" "inline-flex"]
                [ div [ style "width" "70px"]
                      [ text <| (String.fromInt i) ++ "."]
                , div [ style "color" color ] [ text text_ ]
                ]

translateColor : String -> String
translateColor en  =
    case en of
        "red" -> "rot"
        "green" -> "grün"
        "black" -> "schwarz"
        "magenta" -> "magenta"
        "darkorange" -> "orange"
        "gold" -> "gelb"
        _ -> en
