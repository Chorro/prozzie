#!/usr/bin/env bash

# This file is part of Prozzie - The Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018-2019 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##
## @brief      Check module parameters
##
## @param      1     Number of arguments to check
## @param      2     Module name
## @param      @     Parametes to check
##
## @return     Always true
##
genericTestModule() {
    declare description key
    declare -r num_arguments="$1"
    declare -r module_name="$2"
    shift 2

    declare describe_out
    describe_out="$("${PROZZIE_PREFIX}/bin/prozzie" config describe "$module_name" \
        | grep -v 'Module .*')"
    declare -r describe_out

    ${_ASSERT_EQUALS_} '"Incorrect number of arguments"' \
        "${num_arguments}" "$(printf '%s\n' "${describe_out}" | wc -l)"

    declare key_value_list
    key_value_list="$("${PROZZIE_PREFIX}/bin/prozzie" config get "$module_name" \
        | grep -v '#.*')"
    declare -r key_value_list

    ${_ASSERT_EQUALS_} '"Incorrect number of arguments"' \
        "${num_arguments}" "$(printf '%s\n' "${key_value_list}" | wc -l)"

    for key in "$@"; do
    declare expected_value value
        if [[ $key == *'='* ]]; then
            expected_value="${key#*=}"
            key="${key%=*}"
        fi
        description=$(printf '%s\n' "${describe_out}" | grep "${key}")
        # Exists key
        if [[ "${description}" != *"${key}"* ]]; then
                ${_FAIL_} "'key ${key}'"
        fi
        # Exists description
        if [[ "${description}" != *"${key}"* ]]; then
                ${_FAIL_} "'Description ${key}'"
        fi
        # We can ask for that variable
        value=$("${PROZZIE_PREFIX}/bin/prozzie" config get "${module_name}" "${key}")
        if [[ -v expected_value ]]; then
            ${_ASSERT_EQUALS_} "'Expected ${key} value'" "'$expected_value'" "'$value'"
        fi
        unset -v value expected_value
    done
}

##
## @brief      Spawn a process and answer it
##             2,4,... Question to expect
##             3,5,... Answers to question $#-1. Use '{ans1} {ans2}' to provide
##             many answers.
##
## @return     Always true
##
## @return     { description_of_the_return_value }
##
genericSpawnQuestionAnswer() {
    declare question_answers_str=''
    declare -r spawn_cmd="$1"
    shift

    # Fill expect variables, questions and answers
    declare argv=("$@")
    for i in "${!argv[@]}"; do
        # Make a tcl list
        argv[i]="{${argv[i]}}"
    done

    # Questions/answers dictionary
    # Format responses as a valid tcl list and add delete previous buffer
    # content (with \025, prozzie offers default response in this buffer)
    # and return carriage
    declare tcl_answers_declare
    tcl_answers_declare=$(cat <<-EOF
        set answers [dict map {q ans_list} [dict create ${argv[@]}] {
            set ans_list [lmap ans \$ans_list {
                set ans "\\025\$ans\\r"
            }]
        }]
		EOF
        )

    # Build expect answers
    # If the line is too long, prozzie readline interface will write the
    # question again, even if it has been already answered. The user will not
    # notice it because of tty tricks, but expect will do, so expect is only
    # allowed to answer one time. Because of that, expect will do nothing except
    # consume the buffer if it founds the same question again and we are out of
    # responses. This happens in sfacct aggregation variable.
    declare question_answers_str
    question_answers_str="$(tclsh <<-EOF
        $tcl_answers_declare
        foreach question [dict keys \$answers] {
              puts "\\"\$question\\" \\{"
              puts "  set answers_list \\[dict get \\\$answers \\"\$question\\"\\]"
              puts "  send \\"\\[struct::list shift answers_list\\]\\""
              puts "  dict set answers \\"\$question\\" \\\$answers_list"
              puts "  exp_continue"
              puts "\\}"
        }
		EOF
        )"
    declare -r question_answers_str

    # If readline detects few columns, it will add newlines to the output.
    # TODO: Delete all newlines in spawned process output buffer, so
    # COLUMNS=2000 hack is not needed.
    env COLUMNS=2000 expect <<-EOF
        package require struct::list
        $tcl_answers_declare
        set timeout 120
        spawn ${spawn_cmd}
        expect {
            $question_answers_str
            timeout {
                exit 1
            }
            eof
        }
		EOF
}

##
## @brief      Execute a module setup
##
## @param      1 - Module name
##             2,4,... Question to expect
##             3,5,... Answers to question $#-1. Use '{ans1} {ans2}' to provide
##             many answers.
##
## @return     Always true
##
genericSetupQuestionAnswer() {
    genericSpawnQuestionAnswer "${PROZZIE_PREFIX}/bin/prozzie config setup $1" \
                                                                        "${@:2}"
}
