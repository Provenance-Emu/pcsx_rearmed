/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *   linkage_arm.s for PCSX                                                *
 *   Copyright (C) 2009-2011 Ari64                                         *
 *   Copyright (C) 2021 notaz                                              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.          *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include "arm_features.h"
#include "new_dynarec_config.h"
#include "assem_arm64.h"
#include "linkage_offsets.h"

#ifdef __MACH__
#define dynarec_local        ESYM(dynarec_local)
#define ndrc_add_jump_out    ESYM(ndrc_add_jump_out)
#define ndrc_try_restore_block    ESYM(ndrc_try_restore_block)
#define ndrc_get_addr_ht    ESYM(ndrc_get_addr_ht)
#define ndrc_get_addr_ht_param    ESYM(ndrc_get_addr_ht_param)
#define ndrc_write_invalidate_one ESYM(ndrc_write_invalidate_one)
#define gen_interupt        ESYM(gen_interupt)
#define gteCheckStallRaw    ESYM(gteCheckStallRaw)
#define psxException        ESYM(psxException)
#endif

#if (LO_mem_wtab & 7)
#error misligned pointers
#endif

#define GLOBAL_FUNCTION(name)  \
    .globl name;               \
    .hidden name;              \
    name

#define LOCAL_FUNCTION(name)  \
    .hidden name;             \
    name

#define GLOBAL_VARIABLE(name, size_) \
    .globl name;                    \
    .hidden name;

#define ESYM(name) _##name

#define FUNC(name) \
    .globl ESYM(name); \
name: \
ESYM(name)


/*
    .globl _cc_interrupt;
 _cc_interrupt:
 */

.bss
	.align	4
	.globl dynarec_local

    // .type	dynarec_local, %object
	 // .size	dynarec_local, LO_dynarec_local_size

dynarec_local:
	.space	LO_dynarec_local_size

#define DRC_VAR_(name, vname, size_) \
	vname = dynarec_local + LO_##name; \
	.globl vname;

//    .type	vname, %object; \
  //  .size	vname, size_

#define DRC_VAR(name, size_) \
	DRC_VAR_(name, ESYM(name), size_)

_next_interupt = dynarec_local + LO_next_interupt;
.globl _next_interupt;

//DRC_VAR(next_interupt, 4)
_cycle_count = dynarec_local + LO_cycle_count;
.globl _cycle_count;

_last_count = dynarec_local + LO_last_count;
.globl _last_count;

_pending_exception = dynarec_local + LO_pending_exception;
.globl _pending_exception;

_stop = dynarec_local + LO_stop;
.globl _stop;

_branch_target = dynarec_local + LO_branch_target;
.globl _branch_target;

_address = dynarec_local + LO_address;
.globl _address;

_hack_addr = dynarec_local + LO_hack_addr;
.globl _hack_addr;

_psxRegs = dynarec_local + LO_psxRegs;
.globl _psxRegs;


/* psxRegs */
#DRC_VAR(reg, 128)
_lo = dynarec_local + LO_lo;
.globl _lo;

_hi = dynarec_local + LO_hi;
.globl _hi;

_reg_cop0 = dynarec_local + LO_reg_cop0;
.globl _reg_cop0;

_reg_cop2d = dynarec_local + LO_reg_cop2d;
.globl _reg_cop2d;

_reg_cop2c = dynarec_local + LO_reg_cop2c;
.globl _reg_cop2c;

_pcaddr = dynarec_local + LO_pcaddr;
.globl _pcaddr;

#DRC_VAR(code, 4)
#DRC_VAR(cycle, 4)
#DRC_VAR(interrupt, 4)
#DRC_VAR(intCycle, 256)

_rcnts = dynarec_local + LO_rcnts;
.globl _rcnts;


_inv_code_start = dynarec_local + LO_inv_code_start;
.globl _inv_code_start;

_inv_code_end = dynarec_local + LO_inv_code_end;
.globl _inv_code_end;

_mem_rtab = dynarec_local + LO_mem_rtab;
.globl _mem_rtab;


_mem_wtab = dynarec_local + LO_mem_wtab;
.globl _mem_wtab;

_psxH_ptr = dynarec_local + LO_psxH_ptr;
.globl _psxH_ptr;


_invc_ptr = dynarec_local + LO_invc_ptr;
.globl _invc_ptr;

_zeromem_ptr = dynarec_local + LO_zeromem_ptr;
.globl _zeromem_ptr;

_scratch_buf_ptr = dynarec_local + LO_scratch_buf_ptr;
.globl _scratch_buf_ptr;


_ram_offset = dynarec_local + LO_ram_offset;
.globl _ram_offset;


_mini_ht = dynarec_local + LO_mini_ht;
.globl _mini_ht;



	.text
	.align	2

    .globl _dyna_linker;
_dyna_linker:
	/* r0 = virtual target address */
	/* r1 = instruction to patch */
	bl	ndrc_get_addr_ht
	br	x0
	 // .size	dyna_linker, .-dyna_linker

	.align	2
    .globl _cc_interrupt;
_cc_interrupt:
	ldr	w0, [rFP, #LO_last_count]
	add	rCC, w0, rCC
	str	wzr, [rFP, #LO_pending_exception]
	str	rCC, [rFP, #LO_cycle]		/* PCSX cycles */
#	str	rCC, [rFP, #LO_reg_cop0+36]	/* Count */
	mov	x21, lr
1:
	bl	gen_interupt
	mov	lr, x21
	ldr	rCC, [rFP, #LO_cycle]
	ldr	w0, [rFP, #LO_next_interupt]
	ldr	w1, [rFP, #LO_pending_exception]
	ldr	w2, [rFP, #LO_stop]
	str	w0, [rFP, #LO_last_count]
	sub	rCC, rCC, w0
	cbnz	w2, _new_dyna_leave
	cbnz	w1, 2f
	ret
2:
	ldr	w0, [rFP, #LO_pcaddr]
	bl	ndrc_get_addr_ht
	br	x0
	 // .size	cc_interrupt, .-cc_interrupt

	.align	2
    .globl _fp_exception;
_fp_exception:
	mov	w2, #0x10000000
0:
	ldr	w1, [rFP, #LO_reg_cop0+48] /* Status */
	mov	w3, #0x80000000
	str	w0, [rFP, #LO_reg_cop0+56] /* EPC */
	orr	w1, w1, #2
	add	w2, w2, #0x2c
	str	w1, [rFP, #LO_reg_cop0+48] /* Status */
	str	w2, [rFP, #LO_reg_cop0+52] /* Cause */
	add	w0, w3, #0x80
	bl	ndrc_get_addr_ht
	br	x0
	 // .size	fp_exception, .-fp_exception
	.align	2
    .globl _fp_exception_ds;
_fp_exception_ds:
	mov	w2, #0x90000000 /* Set high bit if delay slot */
	b	0b
	 // .size	fp_exception_ds, .-fp_exception_ds

	.align	2
    .globl _jump_break_ds;
_jump_break_ds:
	mov	w0, #0x24
	mov	w1, #1
	b	call_psxException
    .globl _jump_break;
_jump_break:
	mov	w0, #0x24
	mov	w1, #0
	b	call_psxException
    .globl _jump_syscall_ds;
_jump_syscall_ds:
	mov	w0, #0x20
	mov	w1, #1
	b	call_psxException
    .globl _jump_syscall;
_jump_syscall:
	mov	w0, #0x20
	mov	w1, #0

    .globl call_psxException;
call_psxException:
	ldr	w3, [rFP, #LO_last_count]
	str	w2, [rFP, #LO_pcaddr]
	add	rCC, w3, rCC
	str	rCC, [rFP, #LO_cycle]		/* PCSX cycles */
	bl	psxException

	/* note: psxException might do recursive recompiler call from it's HLE code,
	 * so be ready for this */
    .globl _jump_to_new_pc;
_jump_to_new_pc:
	ldr	w1, [rFP, #LO_next_interupt]
	ldr	rCC, [rFP, #LO_cycle]
	ldr	w0, [rFP, #LO_pcaddr]
	sub	rCC, rCC, w1
	str	w1, [rFP, #LO_last_count]
	bl	ndrc_get_addr_ht
	br	x0
	 // .size	jump_to_new_pc, .-jump_to_new_pc

	/* stack must be aligned by 16, and include space for save_regs() use */
	.align	2
    .globl _new_dyna_start;
_new_dyna_start:
	stp	x29, x30, [sp, #-SSP_ALL]!
	ldr	w1,  [x0, #LO_next_interupt]
	ldr	w2,  [x0, #LO_cycle]
	stp	x19, x20, [sp, #16*1]
	stp	x21, x22, [sp, #16*2]
	stp	x23, x24, [sp, #16*3]
	stp	x25, x26, [sp, #16*4]
	stp	x27, x28, [sp, #16*5]
	mov	rFP, x0
	ldr	w0,  [rFP, #LO_pcaddr]
	str	w1,  [rFP, #LO_last_count]
	sub	rCC, w2, w1
	bl	ndrc_get_addr_ht
	br	x0
	 // .size	new_dyna_start, .-new_dyna_start

	.align	2
    .globl _new_dyna_leave;
_new_dyna_leave:
	ldr	w0,  [rFP, #LO_last_count]
	add	rCC, rCC, w0
	str	rCC, [rFP, #LO_cycle]
	ldp	x19, x20, [sp, #16*1]
	ldp	x21, x22, [sp, #16*2]
	ldp	x23, x24, [sp, #16*3]
	ldp	x25, x26, [sp, #16*4]
	ldp	x27, x28, [sp, #16*5]
	ldp	x29, x30, [sp], #SSP_ALL
	ret
	 // .size	new_dyna_leave, .-new_dyna_leave

/* --------------------------------------- */

.align	2

.macro memhandler_pre
	/* w0 = adddr/data, x1 = rhandler, w2 = cycles, x3 = whandler */
	ldr	w4, [rFP, #LO_last_count]
	add	w4, w4, w2
	str	w4, [rFP, #LO_cycle]
.endm

.macro memhandler_post
	ldr	w0, [rFP, #LO_next_interupt]
	ldr	w2, [rFP, #LO_cycle]        // memhandlers can modify cc, like dma
	str	w0, [rFP, #LO_last_count]
	sub	w0, w2, w0
.endm

    .globl _do_memhandler_pre;
_do_memhandler_pre:
	memhandler_pre
	ret

    .globl _do_memhandler_post;
_do_memhandler_post:
	memhandler_post
	ret

.macro pcsx_read_mem readop tab_shift
	/* w0 = address, x1 = handler_tab, w2 = cycles */
	ubfm	w4, w0, \tab_shift, #11
	ldr	x3, [x1, w4, uxtw #3]
	adds	x3, x3, x3
	bcs	0f
	\readop	w0, [x3, w4, uxtw \tab_shift]
	ret
0:
	stp	xzr, x30, [sp, -16]!
	memhandler_pre
	blr	x3
.endm

    .globl _jump_handler_read8;
_jump_handler_read8:
	add     x1, x1, #0x1000/4*8 + 0x1000/2*8  /* shift to r8 part */
	pcsx_read_mem ldrb, 0
	b	_handler_read_end

    .globl _jump_handler_read16;
_jump_handler_read16:
	add     x1, x1, #0x1000/4*8               /* shift to r16 part */
	pcsx_read_mem ldrh, 1
	b	_handler_read_end

    .globl _jump_handler_read32;
_jump_handler_read32:
	pcsx_read_mem ldr, 2

    .globl _handler_read_end;
_handler_read_end:
	ldp	xzr, x30, [sp], #16
	ret

.macro pcsx_write_mem wrtop, movop, tab_shift
	/* w0 = address,f w1 = data, w2 = cycles, x3 = handler_tab */
	ubfm	w4, w0, #\tab_shift, #11
	ldr	x3, [x3, w4, uxtw #3]
	adds	x3, x3, x3
	bcs	0f
	mov	w0, w2                    /* cycle return */
	\wrtop	w1, [x3, w4, uxtw #\tab_shift]
	ret
0:
	stp	xzr, x30, [sp, #-16]!
	str	w0, [rFP, #LO_address]    /* some handlers still need it... */
	\movop	w0, w1
	memhandler_pre
	blr	x3
.endmacro

    .globl _jump_handler_write8;
_jump_handler_write8:
	add     x3, x3, #0x1000/4*8 + 0x1000/2*8  /* shift to r8 part */
	pcsx_write_mem strb, uxtb, 0
	b	handler_write_end

    .globl _jump_handler_write16;
_jump_handler_write16:
	add     x3, x3, #0x1000/4*8               /* shift to r16 part */
	pcsx_write_mem strh, uxth, 1
	b	handler_write_end

    .globl _jump_handler_write32;
_jump_handler_write32:
	pcsx_write_mem str, mov, 2

    .globl handler_write_end;
handler_write_end:
	memhandler_post
	ldp	xzr, x30, [sp], #16
	ret

    .globl _jump_handle_swl;
_jump_handle_swl:
	/* w0 = address, w1 = data, w2 = cycles */
	ldr	x3, [rFP, #LO_mem_wtab]
	orr	w4, wzr, w0, lsr #12
	ldr	x3, [x3, w4, uxtw #3]
	adds	x3, x3, x3
	bcs	4f
	add	x3, x0, x3
	mov	w0, w2
	tbz	x3, #1, 10f	// & 2
	tbz	x3, #0, 2f	// & 1
3:
	stur	w1, [x3, #-3]
	ret
2:
	lsr	w2, w1, #8
	lsr	w1, w1, #24
	sturh	w2, [x3, #-2]
	strb	w1, [x3]
	ret
10:
	tbz	x3, #0, 0f	// & 1
1:
	lsr	w1, w1, #16
	sturh	w1, [x3, #-1]
	ret
0:
	lsr	w2, w1, #24
	strb	w2, [x3]
	ret
4:
	mov	w0, w2		// todo
	bl	_abort
	ret

    .globl _jump_handle_swr;
_jump_handle_swr:
	/* w0 = address, w1 = data, w2 = cycles */
	ldr	x3, [rFP, #LO_mem_wtab]
	orr	w4, wzr, w0, lsr #12
	ldr	x3, [x3, w4, uxtw #3]
	adds	x3, x3, x3
	bcs	4f
	add	x3, x0, x3
	mov	w0, w2
	tbz	x3, #1, 10f	// & 2
	tbz	x3, #0, 2f	// & 1
3:
	strb	w1, [x3]
	ret
2:
	strh	w1, [x3]
	ret
10:
	tbz	x3, #0, 0f	// & 1
1:
	lsr	w2, w1, #8
	strb	w1, [x3]
	sturh	w2, [x3, #1]
	ret
0:
	str	w1, [x3]
	ret
4:
	mov	w0, w2		// todo
	bl	_abort
	ret

    .globl _call_gteStall;
_call_gteStall:
	/* w0 = op_cycles, w1 = cycles */
	ldr	w2, [rFP, #LO_last_count]
	str	lr, [rFP, #LO_saved_lr]
	add	w1, w1, w2
	str	w1, [rFP, #LO_cycle]
	add	x1, rFP, #LO_psxRegs
	bl	gteCheckStallRaw
	ldr	lr, [rFP, #LO_saved_lr]
	add	rCC, rCC, w0
	ret

