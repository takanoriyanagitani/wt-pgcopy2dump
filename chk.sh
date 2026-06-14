#!/bin/sh

wsm="./opt.wasm"
wsm="./pgcopy2dump.wasm"

genpgcopyheader(){
  printf 'PGCOPY'
  printf '\n\xff'
  printf '\r\n'
  printf '\0'
  printf '\0\0\0\0'
  printf '\0\0\0\0'
}

genpgcopy(){
  genpgcopyheader

  printf '\0\3'
  printf '\0\0\0\2'; printf '42'
  printf '\0\0\0\4'; printf '3776'
  printf '\0\0\0\x08'; printf '16777216'

  printf '\0\3'
  printf '\0\0\0\2'; printf '43'
  printf '\0\0\0\4'; printf '2019'
  printf '\0\0\0\x08'; printf 'abcdefgh'

  printf '\xff\xff'

}

genpgcopy |
  wazero run "${wsm}" > tmp
echo $?
echo

cat tmp | python3 -m cbor2.tool --pretty --sequence
#cat tmp | xxd
