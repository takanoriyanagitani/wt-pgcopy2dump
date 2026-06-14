(module

  (import "wasi_snapshot_preview1" "proc_exit" (func $proc_exit (param i32)))

  (import "wasi_snapshot_preview1" "fd_write"
    (func $fd_write (param i32 i32 i32 i32) (result i32)))

  (import "wasi_snapshot_preview1" "fd_read"
    (func $fd_read (param i32 i32 i32 i32) (result i32)))

  (global $STDIN i32 (i32.const 0))
  (global $STDOUT i32 (i32.const 1))
  (global $STDERR i32 (i32.const 2))

  (global $MAX_COL_SIZE i32 (i32.const 32767))

  (global $FD_READ_IOVEC_PTR i32 (i32.const 0x0001_0000))
  (global $FD_READ_IOBUF_PTR i32 (i32.const 0x0002_0000))
  (global $FD_READ_BREAD_PTR i32 (i32.const 0x0003_0000))

  (global $FD_WRIT_IOVEC_PTR i32 (i32.const 0x0004_0000))
  (global $FD_WRIT_IOBUF_PTR i32 (i32.const 0x0005_0000))
  (global $FD_WRIT_BWRIT_PTR i32 (i32.const 0x0006_0000))

  (global $SIG_LEN i32 (i32.const 11))

  (memory (export "memory") 7)

  (func $lng2stdout
    (param $i i64)

    (param $fd i32)
    (param $pvec i32)
    (param $pbuf i32)
    (param $pwrt i32)

    (result i64)

    ;; setup the iovec
    local.get $pvec
    local.get $pbuf
    i32.store
    local.get $pvec
    i32.const 8 ;; 64-bit integer = 8 bytes
    i32.store offset=4

    ;; save the integer
    local.get $pbuf
    local.get $i
    i64.store

    local.get $fd
    local.get $pvec
    i32.const 1 ;; single buffer
    local.get $pwrt
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    local.get $pwrt
    i32.load
    i32.const 8
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $lng2stdout_default
    (param $i i64)
    (result i64)

    local.get $i

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    global.get $FD_WRIT_BWRIT_PTR

    call $lng2stdout
  )

  (func $stdin2sig
    (param $ptr i32)
    (result i64)

    ;; setup the iovec
    global.get $FD_READ_IOVEC_PTR
    local.get $ptr
    i32.store
    global.get $FD_READ_IOVEC_PTR
    global.get $SIG_LEN
    i32.store offset=4

    global.get $STDIN
    global.get $FD_READ_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_READ_BREAD_PTR
    call $fd_read
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_READ_BREAD_PTR
    i32.load
    global.get $SIG_LEN
    i32.ne
    if
      i32.const 2
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $byte2stdout (param $b i32) (result i64)
    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single byte to write
    i32.store offset=4

    ;; copy the byte
    global.get $FD_WRIT_IOBUF_PTR
    local.get $b
    i32.store8

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 1
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $sig2cbor2stdout (param $sigptr i32) (param $siglen i32) (result i64)
    ;; write the cbor tag&len(sig len = 11, which is < 24)
    local.get $siglen
    i32.const 0x0000_0040
    i32.add
    call $byte2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    local.get $sigptr
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    local.get $siglen
    i32.store offset=4

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    local.get $siglen
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $stdin2i32 (result i64 i32)
    ;; setup the iovec
    global.get $FD_READ_IOVEC_PTR
    global.get $FD_READ_IOBUF_PTR
    i32.store
    global.get $FD_READ_IOVEC_PTR
    i32.const 4 ;; 32-bit integer = 4 bytes
    i32.store offset=4

    global.get $STDIN
    global.get $FD_READ_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_READ_BREAD_PTR
    call $fd_read
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      i32.const 0
      return
    end

    global.get $FD_READ_BREAD_PTR
    i32.load
    i32.const 4
    i32.ne
    if
      i32.const 2
      call $proc_exit
      i64.const -1
      i32.const 0
      return
    end

    i64.const 0
    global.get $FD_READ_IOBUF_PTR
    i32.load
  )

  (func $le2be32i (param $i i32) (result i32)
    local.get $i ;; 0xPQRS_XYZW
    i32.const 0x00ff_00ff
    i32.and               ;; 0x00RS_00ZW
    i32.const 8
    i32.shl               ;; 0xRS___ZW__

    local.get $i ;; 0xPQRS_XYZW
    i32.const 0xff00_ff00
    i32.and               ;; 0xPQ00_XY00
    i32.const 8
    i32.shr_u             ;; 0x00PQ_00XY

    i32.or                ;; 0xRSPQ_ZWXY
    i32.const 16
    i32.rotl              ;; 0xZWXY_RSPQ
  )

  (func $integer2stdout (param $i i32) (result i64)
    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 4 ;; 32-bit integer = 4 bytes
    i32.store offset=4

    ;; copy the integer
    global.get $FD_WRIT_IOBUF_PTR
    local.get $i
    i32.store

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 4
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $short2stdout (param $i i32) (result i64)
    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 2 ;; 16-bit integer = 2 bytes
    i32.store offset=4

    ;; copy the integer
    global.get $FD_WRIT_IOBUF_PTR
    local.get $i
    i32.store16

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 2
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $unsigned2cbor2stdout32 (param $i i32) (result i64)
    ;; write the tag for 32-bit unsigned integer
    i32.const 0x0000_001a
    call $byte2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    local.get $i
    call $le2be32i
    call $integer2stdout
  )

  (func $stdin2flags2cbor2stdout (result i64)
    (local $i i32)
    (local $ret i64)

    ;; get the integer
    call $stdin2i32
    local.set $i
    local.tee $ret
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    local.get $i
    call $unsigned2cbor2stdout32
  )

  (func $be2le16 (param $i i32) (result i32)
    local.get $i      ;; 0x0000_XYZW
    i32.const 0x0000_00ff
    i32.and           ;; 0x0000_00ZW
    i32.const 8
    i32.shl           ;; 0x0000_ZW00

    local.get $i      ;; 0x0000_XYZW
    i32.const 8
    i32.shr_u         ;; 0x0000_00XY

    i32.or            ;; 0x0000_ZWXY
  )

  (func $stdin2colcnt (result i64 i32)
    (local $colcnt i32)
    ;; setup the iovec
    global.get $FD_READ_IOVEC_PTR
    global.get $FD_READ_IOBUF_PTR
    i32.store
    global.get $FD_READ_IOVEC_PTR
    i32.const 2 ;; 16-bit integer = 2 bytes
    i32.store offset=4

    global.get $STDIN
    global.get $FD_READ_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_READ_BREAD_PTR
    call $fd_read
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      i32.const 0
      return
    end

    global.get $FD_READ_BREAD_PTR
    i32.load
    i32.const 2
    i32.ne
    if
      i32.const 2
      call $proc_exit
      i64.const -1
      i32.const 0
      return
    end

    global.get $FD_READ_IOBUF_PTR
    i32.load16_s
    local.set $colcnt

    local.get $colcnt
    i32.const -1
    i32.eq
    if
      i32.const 0
      call $proc_exit
      i64.const 0
      i32.const 0
      return
    end

    i64.const 0
    local.get $colcnt
    call $be2le16
  )

  (func $stdin2read_full_or_error (param $size i32) (result i64)
    (local $read_cnt_tot i32)
    (local $read_cnt_cur i32)

    (local $byte_cnt2read i32)

    i32.const 0
    local.tee $read_cnt_tot
    local.tee $read_cnt_cur

    loop
      ;; compute the byte count to read
      local.get $size
      local.get $read_cnt_tot
      i32.sub
      local.tee $byte_cnt2read
      i32.const 0
      i32.le_s
      ;; return when no bytes to read
      if
        i64.const 0
        return
      end

      ;; setup the iovec
      global.get $FD_READ_IOVEC_PTR
      ;;;; compute the buf ptr
      global.get $FD_READ_IOBUF_PTR
      local.get $read_cnt_tot
      i32.add
      i32.store
      global.get $FD_READ_IOVEC_PTR
      local.get $byte_cnt2read
      i32.store offset=4

      global.get $STDIN
      global.get $FD_READ_IOVEC_PTR
      i32.const 1 ;; single buffer
      global.get $FD_READ_BREAD_PTR
      call $fd_read
      i32.const 0
      i32.ne
      if
        i32.const 1
        call $proc_exit
        i64.const -1
        return
      end

      global.get $FD_READ_BREAD_PTR
      i32.load
      local.tee $read_cnt_cur
      local.get $read_cnt_tot
      i32.add
      local.set $read_cnt_tot

      local.get $read_cnt_cur
      i32.const 0
      i32.eq
      ;; EOF
      if
        local.get $read_cnt_tot
        local.get $size
        i32.ne
        ;; unexpected EOF
        if
          i32.const 2
          call $proc_exit
          i64.const -1
          return
        end

        i64.const 0
        return
      end

      br 0
    end

    unreachable
  )

  (func $buf2stdout (param $ptr i32) (param $len i32) (result i64)
    ;; write the tag
    i32.const 0x0000_005a
    call $byte2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    ;; write the len
    local.get $len
    call $le2be32i
    call $integer2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    local.get $ptr
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    local.get $len
    i32.store offset=4

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    local.get $len
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $stdin2colvalue2cbor2stdout (param $colsize i32) (result i64)
    ;; check the col size
    global.get $MAX_COL_SIZE
    local.get $colsize
    i32.lt_u
    if
      i32.const 2
      call $proc_exit
      i64.const -1
      return
    end

    local.get $colsize
    call $stdin2read_full_or_error
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_READ_IOBUF_PTR
    local.get $colsize
    call $buf2stdout
  )

  (func $null2cbor2stdout  (result i64)
    ;; setup the iovec
    global.get $FD_WRIT_IOVEC_PTR
    global.get $FD_WRIT_IOBUF_PTR
    i32.store
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; null tag = single byte
    i32.store offset=4

    ;; set the null tag
    global.get $FD_WRIT_IOBUF_PTR
    i32.const 0x0000_00f6
    i32.store8

    global.get $STDOUT
    global.get $FD_WRIT_IOVEC_PTR
    i32.const 1 ;; single buffer
    global.get $FD_WRIT_BWRIT_PTR
    call $fd_write
    i32.const 0
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    global.get $FD_WRIT_BWRIT_PTR
    i32.load
    i32.const 1
    i32.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    i64.const 0
  )

  (func $col2cbor2stdout (result i64)
    (local $colsize i32)
    (local $ret i64)

    ;; get the col size
    call $stdin2i32
    local.set $colsize
    local.tee $ret
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    local.get $colsize
    call $le2be32i
    local.tee $colsize
    call $unsigned2cbor2stdout32
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    local.get $colsize
    i32.const -1
    i32.eq
    ;; if the colsize = -1(0xffff_ffff), it's null
    if
      call $null2cbor2stdout
      return
    end

    ;; read the col val and write as cbor bytes
    local.get $colsize
    call $stdin2colvalue2cbor2stdout
  )

  (func $row2cbor2stdout (param $colcnt i32) (result i64)
    (local $icol i32)

    i32.const 1
    local.set $icol

    ;; print the col cnt
    ;;;; write the tag
    i32.const 0x0000_0019
    call $byte2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end
    ;;;; write the col cnt
    local.get $colcnt
    call $be2le16
    call $short2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      i64.const -1
      return
    end

    loop
      local.get $colcnt
      local.get $icol
      i32.lt_u
      ;; no more col to process
      if
        i64.const 0
        return
      end

      call $col2cbor2stdout
      i64.const 0
      i64.ne
      if
        i32.const 1
        call $proc_exit
        i64.const -1
        return
      end

      local.get $icol
      i32.const 1
      i32.add
      local.set $icol

      br 0
    end

    unreachable
  )

  (func $rows2cbor2stdout (result i64)
    (local $colcnt i32)
    (local $ret i64)

    loop
      ;; get the col cnt from stdin
      call $stdin2colcnt
      local.set $colcnt
      local.tee $ret
      i64.const 0
      i64.ne
      if
        i32.const 1
        call $proc_exit
        i64.const -1
        return
      end

      local.get $colcnt
      i32.const -1
      i32.eq
      ;; EOF
      if
        i64.const 0
        return
      end

      local.get $colcnt
      call $row2cbor2stdout
      i64.const 0
      i64.ne
      if
        i32.const 1
        call $proc_exit
        i64.const -1
        return
      end

      br 0
    end

    unreachable
  )

  (func $main (export "_start")
    ;; get the header and print it as cbor
    ;;;; read the sig
    global.get $FD_READ_IOBUF_PTR
    call $stdin2sig
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end
    ;;;; write the sig
    global.get $FD_READ_IOBUF_PTR
    global.get $SIG_LEN
    call $sig2cbor2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end

    ;; get the flags field and print it as cbor
    call $stdin2flags2cbor2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end

    ;; get the ext info and print it as cbor
    call $stdin2flags2cbor2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end

    call $rows2cbor2stdout
    i64.const 0
    i64.ne
    if
      i32.const 1
      call $proc_exit
      return
    end
  )

)
