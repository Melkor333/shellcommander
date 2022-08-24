#!/usr/bin/env bash

bats_prefix_lines_for_tap_output() {
    while IFS= read -r line; do
      printf '# %s\n' "$line" || break # avoid feedback loop when errors are redirected into BATS_OUT (see #353)
    done
    if [[ -n "$line" ]]; then
      printf '# %s\n' "$line"
    fi
}

function bats_replace_filename() {
  local line
  while read -r line; do
    printf "%s\n" "${line//$BATS_TEST_SOURCE/$BATS_TEST_FILENAME}"
  done
  if [[ -n "$line" ]]; then
    printf "%s\n" "${line//$BATS_TEST_SOURCE/$BATS_TEST_FILENAME}"
  fi
}

bats_quote_code() { # <var> <code>
	printf -v "$1" -- "%s%s%s" "$BATS_BEGIN_CODE_QUOTE" "$2" "$BATS_END_CODE_QUOTE"
}

bats_check_valid_version() {
  if [[ ! $1 =~ [0-9]+.[0-9]+.[0-9]+ ]]; then
    printf "ERROR: version '%s' must be of format <major>.<minor>.<patch>!\n" "$1" >&2
    exit 1
  fi
}

# compares two versions. Return 0 when version1 < version2
bats_version_lt() { # <version1> <version2>
  bats_check_valid_version "$1"
  bats_check_valid_version "$2"

  local -a version1_parts version2_parts
  IFS=. read -ra version1_parts <<< "$1"
  IFS=. read -ra version2_parts <<< "$2"

  for i in {0..2}; do
    if (( version1_parts[i] < version2_parts[i] )); then
      return 0
    elif (( version1_parts[i] > version2_parts[i] )); then
      return 1
    fi
  done
  # if we made it this far, they are equal -> also not less then
  return 2 # use other failing return code to distinguish equal from gt
}

# ensure a minimum version of bats is running or exit with failure
bats_require_minimum_version() { # <required version>
  local required_minimum_version=$1

  if bats_version_lt "$BATS_VERSION" "$required_minimum_version"; then
    printf "BATS_VERSION=%s does not meet required minimum %s\n" "$BATS_VERSION" "$required_minimum_version"
    exit 1
  fi

  if bats_version_lt "$BATS_GUARANTEED_MINIMUM_VERSION" "$required_minimum_version"; then
    BATS_GUARANTEED_MINIMUM_VERSION="$required_minimum_version"
  fi
}

bats_binary_search() { # <search-value> <array-name>
  if [[ $# -ne 2 ]]; then
    printf "ERROR: bats_binary_search requires exactly 2 arguments: <search value> <array name>\n" >&2
    return 2
  fi

  local -r search_value=$1 array_name=$2
  
  # we'd like to test if array is set but we cannot distinguish unset from empty arrays, so we need to skip that

  local start=0 mid end mid_value 
  # start is inclusive, end is exclusive ...
  eval "end=\${#${array_name}[@]}"

  # so start == end means empty search space
  while (( start < end )); do
    mid=$(( (start + end) / 2 ))
    eval "mid_value=\${${array_name}[$mid]}"
    if [[ "$mid_value" == "$search_value" ]]; then
      return 0
    elif [[ "$mid_value" < "$search_value" ]]; then
      # This branch excludes equality -> +1 to skip the mid element.
      # This +1 also avoids endless recursion on odd sized search ranges.
      start=$((mid + 1))
    else
      end=$mid
    fi
  done

  # did not find it -> its not there
  return 1
}

# store the values in ascending order in result array
# Intended for short lists!
bats_sort() { # <result-array-name> <values to sort...>
  local -r result_name=$1
  local -a sorted_array=()
  shift
  local -i j i=0
  for (( j=1; j <= $#; ++j )); do
    for ((i=${#sorted_array[@]}; i >= 0; --i )); do
      if [[ $i -eq 0 || ${sorted_array[$((i-1))]} < ${!j} ]]; then
        sorted_array[$i]=${!j}
        break
      else
        sorted_array[$i]=${sorted_array[$((i-1))]}
      fi
    done
  done

  eval "$result_name=(\"\${sorted_array[@]}\")"
}

# check if all search values (must be sorted!) are in the (sorted!) array
# Intended for short lists/arrays!
bats_all_in() { # <sorted-array> <sorted search values...>
  local -r haystack_array=$1
  shift

  local -i haystack_length # just to appease shellcheck
  eval "local -r haystack_length=\${#${haystack_array}[@]}"
  
  local -i haystack_index=0 # initialize only here to continue from last search position
  local search_value haystack_value # just to appease shellcheck
  for (( i=1; i <= $#; ++i )); do
    eval "local search_value=${!i}"
    for ((; haystack_index < haystack_length; ++haystack_index)); do
      eval "local haystack_value=\${${haystack_array}[$haystack_index]}"
      if [[ $haystack_value > "$search_value" ]]; then
        # we passed the location this value would have been at -> not found
        return 1
      elif [[ $haystack_value == "$search_value" ]]; then
        continue 2 # search value found  -> try the next one
      fi
    done
    return 1 # we ran of the end of the haystack without finding the value!
  done

  # did not return from loop above -> all search values were found
  return 0
}

bats_trim () { # <output-variable> <string>
  local -r bats_trim_ltrimmed=${2#"${2%%[![:space:]]*}"} # cut off leading whitespace
  local -r bats_trim_trimmed=${bats_trim_ltrimmed%"${bats_trim_ltrimmed##*[![:space:]]}"} # cut off trailing whitespace
  printf -v "$1" "%s" "$bats_trim_trimmed"
}
