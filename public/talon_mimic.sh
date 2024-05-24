TALON_REPL_PATH=${TALON_REPL_PATH}

source ~/bashrc_dir/private/path.sh

function m() {
  # Check if Talon is asleep
  get_state
  # Capture output of last command with $? (either 0 or 1)
  # Assign talon_state based on $?
  talon_state=$(if [ $? -eq 0 ]; then echo "True"; else echo "False"; fi)
  get_state $talon_state start

  # begin an empty command
  command=""
  # loop over all arguments passed to the function
  for word in "$@"; do
    # If , or . are found at the end an argument
    if [[ "$word" == *, || "$word" == *. ]]; then
      # remove , or . from the argument
      word=$(echo "${word}" | tr -d ',.')
      # add the current argument to the command
      # This initially adds a space character to the front of the command as well
      command="$command $word"
      # Remove leading whitespace
      command="${command#"${command%%[![:space:]]*}"}"
      # Remove trailing whitespace
      command="${command%"${command##*[![:space:]]}"}"
      # Pipe the command to the talon repl running mimic
      mimic "${command/ /}"
      # Pipe a short sleep between each command
      repl_func "actions.sleep(.05)"
      command="" 
    # if no , or . are found in the argument
    # append the argument to the command
    else
      command="$command $word"
    fi
  done
  # Run the last saved command
  mimic "${command/ /}"

  # If Talon was initially asleep, put it back to sleep
  get_state $talon_state end
}

function M() {
  # Check if Talon is asleep
  get_state
  # Capture output of last command with $? (either 0 or 1)
  # Assign talon_state based on $?
  talon_state=$(if [ $? -eq 0 ]; then echo "True"; else echo "False"; fi)
  get_state $talon_state start

  # Change to the last used window
  mimic "command tab"
  # Send a short sleep
  repl_func "actions.sleep(.05)"
  # Run commands after `M`
  m "$@"
  # Send a short sleep
  repl_func "actions.sleep(.05)"
  # Restore back the original used window
  # (as long as no other window changing commands are used)
  mimic "command tab"

  get_state $talon_state end
}

function get_state() {
  # Capture the output of the actions.speech.enabled() command
  talon_state=$(echo "actions.speech.enabled()" | $TALON_REPL_PATH | tail -n 1)

  # If the first argument is False, execute the echo command
  if [[ $1 == "False" ]]; then
    if [[ $2 == "start" ]]; then
        mimic "talon wake"
    fi

    if [[ $2 == "end" ]]; then
    mimic "talon sleep"
    fi
  fi

  # Check if Talon is awake
  if [[ "$talon_state" == "True" ]]; then
    return 0 
  else
    return 1
  fi
}

function mimic() {
  echo "mimic(\"$1\")"| $TALON_REPL_PATH > /dev/null
}

function repl_func() {
  echo $1 | $TALON_REPL_PATH > /dev/null
}

export -f m
export -f M