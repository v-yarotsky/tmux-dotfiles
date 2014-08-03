#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
MSG_WIDTH=$(expr $(tput cols) - 13)

function echo_step() {
  printf "%-*s%s" "$MSG_WIDTH" "$1"
}

function echo_ok() {
  printf " %s%s%s\n" "$GREEN" "[OK]" "$NORMAL"
}

function echo_err() {
  printf " %s%s%s\n" "$RED" "[FAIL]" "$NORMAL"
}

function echo_hint() {
  if [ -n "$1" ]; then
    echo >&2 "$1"
  fi
}

trap "echo Oh noes! All your base no belong to us :(" EXIT

UNAME=$(uname)
TMUX_CONF_D="$HOME/.tmux.conf.d"

if [ "$UNAME" != "Linux" -a "$UNAME" != "Darwin" ]; then
  echo_hint "Only Linux and OS X are supported, as of 2014"
fi

if [ "$UNAME" = "Darwin" ]; then
  echo_step "Checking reattach-to-user-namespace is installed"
  if ! hash reattach-to-user-namespace 2>/dev/null; then
    echo_err
    echo_hint "reattach-to-user-namespaces is not installed"
    echo_hint "You can install it by running:\n  brew install reattach-to-user-namespace --wrap-pbcopy-and-pbpaste"
  else
    echo_ok
  fi
fi

COMPILED_CONF="$TMUX_CONF_D/tmux.conf"
SYMLINKED_CONF="$HOME/.tmux.conf"
THEME=${1:-darkspectrum}
THEME_ROOT="$TMUX_CONF_D/themes"

if [ ! -f "$COMPILED_CONF" ]; then
  echo_step "Making a config"

  if [ ! -d "$THEME_ROOT/$THEME" ]; then
    echo_err
    echo_hint "Theme $THEME does not exist. Available themes:"
    echo_hint "$(ls- 1 $THEME_ROOT)"
  fi

  > $COMPILED_CONF
  cat "$TMUX_CONF_D/tmux.conf.Base" >> $COMPILED_CONF
  echo "" >> $COMPILED_CONF
  cat "$TMUX_CONF_D/tmux.conf.$UNAME" >> $COMPILED_CONF
  echo "" >> $COMPILED_CONF
  cat "$THEME_ROOT/$THEME/$THEME.Base" >> $COMPILED_CONF
  echo "" >> $COMPILED_CONF
  cat "$THEME_ROOT/$THEME/$THEME.$UNAME" >> $COMPILED_CONF
  echo_ok
else
  echo "$COMPILED_CONF already exists. Skipping."
fi

echo_step "Symlinking config to $SYMLINKED_CONF"
if [ ! -f "$SYMLINKED_CONF" ]; then
  ln -s $COMPILED_CONF $SYMLINKED_CONF
  echo_ok
else
  echo_err
  echo_hint "$SYMLINKED_CONF already exists. I will not overwrite it."
  echo_hint "Remove it cautiously, then run this:"
  echo_hint "ln -s $COMPILED_CONF $SYMLINKED_CONF"
fi

echo_hint "Don't forget to remap your Caps Lock to Control, it'll make your life MUCH easier!"

echo "Done."

trap - EXIT
