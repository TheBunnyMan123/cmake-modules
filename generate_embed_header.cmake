# Copyright 2026 TheBunnyMan123
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.20)
set(EMBEDDER_SCRIPT_PATH "${CMAKE_CURRENT_LIST_FILE}")

if(CMAKE_SCRIPT_MODE_FILE)
	set(FINAL_CONTENT "#ifndef GENERATED_EMBEDS_H\n#define GENERATED_EMBEDS_H\n#include <stddef.h>")


	if(RECURSE)
		file(GLOB_RECURSE EMBEDS_GLOB LIST_DIRECTORIES FALSE "${IN_DIR}/*")
	else()
		file(GLOB EMBEDS_GLOB LIST_DIRECTORIES FALSE "${IN_DIR}/*")
	endif()

	foreach(FILE_TO_EMBED ${EMBEDS_GLOB})
		get_filename_component(FILE_NAME "${FILE_TO_EMBED}" NAME_WE)
		file(READ "${FILE_TO_EMBED}" FILE_HEX HEX)

		string(REGEX REPLACE "([0-9a-f][0-9a-f])" "0x\\1, " FORMATTED_BYTES "${FILE_HEX}")
		string(MAKE_C_IDENTIFIER "${FILE_NAME}" FILE_IDENTIFIER)
		string(TOUPPER "${FILE_IDENTIFIER}" FILE_IDENTIFIER)
		
		string(LENGTH "${FILE_HEX}" FILE_LEN)
		math(EXPR FILE_LEN "${FILE_LEN} / 2")
		
		if("${NULL_TERMINATE}")
			string(CONCAT FINAL_CONTENT "${FINAL_CONTENT}\n" "const char ${VAR_PREFIX}${FILE_IDENTIFIER}[] = {${FORMATTED_BYTES}0x00};")
			math(EXPR FILE_LEN "${FILE_LEN} + 1")
		else()
			string(REGEX REPLACE ", $" "" FORMATTED_BYTES "${FORMATTED_BYTES}")
			string(CONCAT FINAL_CONTENT "${FINAL_CONTENT}\n" "const char ${VAR_PREFIX}${FILE_IDENTIFIER}[] = {${FORMATTED_BYTES}};")
		endif()
		string(CONCAT FINAL_CONTENT "${FINAL_CONTENT}\n" "const size_t ${VAR_PREFIX}${FILE_IDENTIFIER}_LENGTH = ${FILE_LEN};")
	endforeach()

	string(CONCAT FINAL_CONTENT "${FINAL_CONTENT}\n" "#endif")

	message("Writing to ${OUT_FILE}")
	file(WRITE "${OUT_FILE}" "/* Generated file. Please do not edit. */\n\n${FINAL_CONTENT}")
endif()

function(add_embed_header IN_DIR OUT_FILE VAR_PREFIX RECURSE NULL_TERMINATE)
	add_custom_command(
		OUTPUT "${OUT_FILE}"
		COMMAND	"${CMAKE_COMMAND}"
			"-DIN_DIR=${IN_DIR}"
			"-DOUT_FILE=${OUT_FILE}"
			"-DVAR_PREFIX=${VAR_PREFIX}"
			"-DRECURSE=${RECURSE}"
			"-DNULL_TERMINATE=${NULL_TERMINATE}"
			-P "${EMBEDDER_SCRIPT_PATH}"
		DEPENDS "${INPUT_DIR}" "${EMBEDDER_SCRIPT_PATH}"
		COMMENT "Generating ${OUT_FILE}"
		VERBATIM)

	string(MAKE_C_IDENTIFIER "${OUT_FILE}" OUT_FILE_C)
	add_custom_target(generated_${OUT_FILE_C} ALL
		DEPENDS "${OUT_FILE}"
	)
endfunction()

