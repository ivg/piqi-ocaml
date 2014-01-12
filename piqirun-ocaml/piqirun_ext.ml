(*
   Copyright 2009, 2010, 2011, 2012, 2013 Anton Lavrik

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)

(* Runtime support for JSON-XML-Protobuf-Piq serialization
 *
 * This module is used by OCaml modules generated by
 * "piqic-ocaml --multi-format" Piqi compiler
 *)


type input_format = [ `piq | `json | `xml | `pb | `pib ]

type output_format = [ input_format | `json_pretty | `xml_pretty ]

type piqtype = Piqi_common.T.piqtype

type options = Piqi_convert.options


let _ =
  Piqi_convert.init ()


let add_piqi (piqi_bin: string) =
  let buf = Piqi_piqirun.init_from_string piqi_bin in
  let piqi = Piqi.piqi_of_pb buf in
  Piqi_db.add_piqi piqi;
  ()


let seen = ref []

let init_piqi piqi_list =
  if not (List.memq piqi_list !seen)
  then (
    seen:= piqi_list :: !seen;
    List.iter add_piqi piqi_list
  )


let find_piqtype (typename :string) :piqtype =
  Piqi_convert.find_piqtype typename


(* preallocate default convert options *)
let default_options = Piqi_convert.make_options ()

let default_options_no_pp =
  {
    default_options with
    Piqi_convert.pretty_print = false
  }


let make_options = Piqi_convert.make_options


let convert
        ?opts
        (piqtype :piqtype)
        (input_format :input_format)
        (output_format :output_format)
        (data :string) :string =
  if output_format = (input_format :> output_format)
  then data
  else (
    (* resetting source location tracking back to "enabled" state; we don't
     * carefully call matching Piqloc.resume () for every Piqloc.pause () if we
     * get exceptions in between *)
    Piqloc.is_paused := 0;
    let output_format, default_opts =
      match output_format with
        | `json_pretty -> `json, default_options
        | `xml_pretty -> `xml, default_options
        | (#input_format as x) -> x, default_options_no_pp
    in
    let opts =
      match opts with
        | None -> default_opts
        | Some x -> x
    in
    Piqi_convert.convert_piqtype piqtype input_format output_format data ~opts
  )

