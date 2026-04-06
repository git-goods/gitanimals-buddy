#!/bin/bash
# mood.sh — Usage %에 따른 mood 매핑 및 mood별 표정/대사 제공
# Usage: source this file, then call get_mood, get_mood_bubble, get_mood_compact_face

# usage % → mood 문자열
get_mood() {
  local usage="${1:-}"
  [ -z "$usage" ] && echo "normal" && return
  if [ "$usage" -ge 90 ] 2>/dev/null; then
    echo "panic"
  elif [ "$usage" -ge 70 ] 2>/dev/null; then
    echo "worried"
  elif [ "$usage" -ge 40 ] 2>/dev/null; then
    echo "normal"
  else
    echo "happy"
  fi
}

# mood별 말풍선 대사 (랜덤 1개)
get_mood_bubble() {
  local mood="${1:-normal}"
  local msgs
  case "$mood" in
    happy)
      msgs=("Let's code!" "Nice work~" "I'm here!" "Go go go!" "Ship it!" "You got this!" "Yay~!")
      ;;
    normal)
      msgs=("Keep going~" "Focus time!" "Steady~" "On track!" "Doing good!")
      ;;
    worried)
      msgs=("Getting tight..." "Save some..." "Be careful~" "Hmm..." "Watch out!")
      ;;
    panic)
      msgs=("Running low!!" "Almost out!" "Help!!" "Ahhh!!" "Save me!")
      ;;
  esac
  echo "${msgs[$(( $(date +%S) % ${#msgs[@]} ))]}"
}

# mood별 compact face (pet_type, mood)
get_mood_compact_face() {
  local pet_type="${1:-}" mood="${2:-normal}"
  local pet_lower
  pet_lower=$(echo "$pet_type" | tr '[:upper:]' '[:lower:]')

  case "$pet_lower" in
    rabbit)
      case "$mood" in
        happy)   echo "( 'ㅅ' )" ;;
        normal)  echo "( ·ㅅ· )" ;;
        worried) echo "( ;ㅅ; )" ;;
        panic)   echo "( >ㅅ< )" ;;
      esac
      ;;
    goose)
      case "$mood" in
        happy)   echo "(o>)~" ;;
        normal)  echo "(o>)"  ;;
        worried) echo "(o<)"  ;;
        panic)   echo "(X>)!" ;;
      esac
      ;;
    cat)
      case "$mood" in
        happy)   echo "(^.^)"  ;;
        normal)  echo "(·.·)"  ;;
        worried) echo "(;.;)"  ;;
        panic)   echo "(>.<)"  ;;
      esac
      ;;
    penguin)
      case "$mood" in
        happy)   echo "(^^)/"  ;;
        normal)  echo "(^^)"   ;;
        worried) echo "(;;)"   ;;
        panic)   echo "(XX)"   ;;
      esac
      ;;
    little_chick)
      case "$mood" in
        happy)   echo "(°v°)/" ;;
        normal)  echo "(°v°)"  ;;
        worried) echo "(°~°)"  ;;
        panic)   echo "(°Д°)"  ;;
      esac
      ;;
    capybara)
      case "$mood" in
        happy)   echo "(*u*)"  ;;
        normal)  echo "(*_*)"  ;;
        worried) echo "(*~*)"  ;;
        panic)   echo "(*0*)"  ;;
      esac
      ;;
    pig)
      case "$mood" in
        happy)   echo "(ꈍᴗꈍ)" ;;
        normal)  echo "(ꈍ.ꈍ)" ;;
        worried) echo "(ꈍ~ꈍ)" ;;
        panic)   echo "(ꈍ0ꈍ)" ;;
      esac
      ;;
    slime)
      case "$mood" in
        happy)   echo "(~u~)" ;;
        normal)  echo "(~.~)" ;;
        worried) echo "(~;~)" ;;
        panic)   echo "(~X~)" ;;
      esac
      ;;
    hamster)
      case "$mood" in
        happy)   echo "(•ᴗ•)" ;;
        normal)  echo "(•ᴥ•)" ;;
        worried) echo "(•_•)" ;;
        panic)   echo "(•Д•)" ;;
      esac
      ;;
    sloth)
      case "$mood" in
        happy)   echo "(-u-)" ;;
        normal)  echo "(-_-)" ;;
        worried) echo "(-~-)" ;;
        panic)   echo "(-0-)" ;;
      esac
      ;;
    *)
      case "$mood" in
        happy)   echo "(◦◦)/" ;;
        normal)  echo "(◦◦)"  ;;
        worried) echo "(◦~◦)" ;;
        panic)   echo "(◦X◦)" ;;
      esac
      ;;
  esac
}
