module Date exposing (Date, getTodayLastYear, toString)

import Task
import Time


type alias Date =
    { year : Int
    , month : Time.Month
    , day : Int
    }


getTodayLastYear : Task.Task x Date
getTodayLastYear =
    Task.map subtractOneYear <| Task.map2 toDate Time.here Time.now


subtractOneYear : Date -> Date
subtractOneYear date =
    { date | year = date.year - 1 }


toDate : Time.Zone -> Time.Posix -> Date
toDate z p =
    { year = Time.toYear z p
    , month = Time.toMonth z p
    , day = Time.toDay z p
    }


toString : Date -> String
toString { year, month, day } =
    String.fromInt year
        ++ "-"
        ++ monthToNumberString month
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt day)


monthToNumberString : Time.Month -> String
monthToNumberString month =
    case month of
        Time.Jan ->
            "01"

        Time.Feb ->
            "02"

        Time.Mar ->
            "03"

        Time.Apr ->
            "04"

        Time.May ->
            "05"

        Time.Jun ->
            "06"

        Time.Jul ->
            "07"

        Time.Aug ->
            "08"

        Time.Sep ->
            "09"

        Time.Oct ->
            "10"

        Time.Nov ->
            "11"

        Time.Dec ->
            "12"
