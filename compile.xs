#define PERL_NO_GET_CONTEXT 1
#ifdef WIN32
#  define NO_XSLOCKS
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

OP*
MY_pp_entereval_compile_only(pTHX)
{
    dSP;
    OP* orig_next = PL_op->op_next;
    OP* retop = PL_ppaddr[OP_ENTEREVAL](aTHX);
    if ( retop != orig_next ) {
        /* code compiled! give them a true value */
        PL_ppaddr[OP_LEAVEEVAL](aTHX);
        SETs(&PL_sv_yes);
    }
    else {
        /* should never happen... failing to compile should jump over this op */
        SETs(&PL_sv_no);
    }
    RETURN;
}

static OP *
S_ck_replace_entersub_with_myeval(pTHX_ OP *entersubop, GV *namegv, SV *cv)
{
    OP* new_op;
    OP* pushop;
    OP* realop;

    pushop = cUNOPx(entersubop)->op_first;
    if (!pushop->op_sibling)
       pushop = cUNOPx(pushop)->op_first;

    realop = pushop->op_sibling;
    if (!realop || !realop->op_sibling)
       return entersubop;

    pushop->op_sibling = realop->op_sibling;
    realop->op_sibling = NULL;
    op_free(entersubop);

    new_op = newUNOP(OP_ENTEREVAL, 0, realop);
    new_op->op_ppaddr = MY_pp_entereval_compile_only;
    return new_op;
}


MODULE = eval::compile		PACKAGE = eval::compile		

PROTOTYPES: DISABLE

BOOT:
{
    CV * const cv = get_cvn_flags("eval::compile::compile", 22, 1);
    cv_set_call_checker(cv, S_ck_replace_entersub_with_myeval, &PL_sv_undef);
}

