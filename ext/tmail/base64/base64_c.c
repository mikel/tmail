/*

    base64.c

    Copyright (c) 2001-2007 Minero Aoki

    This program is free software.
    You can distribute/modify this program under the terms of
    the GNU Lesser General Public License version 2.1.


*/


#include "ruby.h"
#include "version.h"
#include <stdio.h>

#ifdef DEBUG
#  define D(code) code
#else
#  define D(code)
#endif

static char *CONVTAB =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static int REVTAB[256];
#define INIT    (-1)
#define SKIP    (-2)
#define ILLEGAL (-3)

#if RUBY_VERSION_CODE < 170   /* Ruby 1.6 */
# define StringValue(s) tmail_rb_string_value(&(s))
static void
tmail_rb_string_value(s)
    VALUE *s;
{
    if (TYPE(*s) != T_STRING) {
        *s = rb_str_to_str(*s);
    }
}
#endif

static void
get_ptrlen(s, ptr, len)
    VALUE *s;
    char **ptr;
    long *len;
{
    StringValue(*s);
    *ptr = RSTRING(*s)->ptr;
    if (!*ptr) *ptr = "";
    *len = RSTRING(*s)->len;
}

static long
calculate_buflen(len, eollen, limit)
    long len, eollen;
{
    long result;

    result = (len/3 + 1) * 4;
    if (eollen) {
        result += (result/limit + 1) * eollen;
    }
    return result;
}

static VALUE
do_base64(str, eolv, limit)
    VALUE str, eolv;
    long limit;
{
    char *buf, *b;
    char *p, *pend;
    long len;
    char *eol;
    long eollen;
    VALUE s;
    char *linehead;

    get_ptrlen(&str, &p, &len);
    pend = p + len;
    if (NIL_P(eolv)) {
        eol = "";
        eollen = 0;
    }
    else {
        get_ptrlen(&eolv, &eol, &eollen);
    }
    b = buf = ALLOC_N(char, calculate_buflen(len, eollen, limit));
    linehead = b;

    while (pend - p >= 3) {
        if (eollen) {
            if (b - linehead + 4 > limit) {
                memcpy(b, eol, eollen); b += eollen;
                linehead = b;
            }
        }
        *b++ = CONVTAB[0x3f & (p[0] >> 2)];
        *b++ = CONVTAB[0x3f & (((p[0] << 4) & 0x30) | ((p[1] >> 4) & 0xf))];
        *b++ = CONVTAB[0x3f & (((p[1] << 2) & 0x3c) | ((p[2] >> 6) & 0x3))];
        *b++ = CONVTAB[0x3f & p[2]];
        p += 3;
    }
    if ((b - linehead) + (pend - p) > limit) {
        if (eollen) {
            memcpy(b, eol, eollen); b += eollen;
        }
    }
    if (pend - p == 2) {
        *b++ = CONVTAB[0x3f & (p[0] >> 2)];
        *b++ = CONVTAB[0x3f & (((p[0] << 4) & 0x30) | ((p[1] >> 4) &0xf))];
        *b++ = CONVTAB[0x3f & (((p[1] << 2) & 0x3c) | 0)];
        *b++ = '=';
    }
    else if (pend - p == 1) {
        *b++ = CONVTAB[0x3f & (p[0] >> 2)];
        *b++ = CONVTAB[0x3f & (((p[0] << 4) & 0x30) | 0)];
        *b++ = '=';
        *b++ = '=';
    }
    if (eollen) {
        memcpy(b, eol, eollen); b += eollen;
    }

    s = rb_str_new("", 0);
    rb_str_cat(s, buf, b - buf);
    free(buf);

    return s;
}

#define DEFAULT_LINE_LIMIT 72

/* def folding_encode( str, eol, limit ) */
static VALUE
b64_fold_encode(argc, argv, self)
    int argc;
    VALUE *argv;
    VALUE self;
{
    VALUE str, eol, limit_v;
    long limit = DEFAULT_LINE_LIMIT;

    switch (rb_scan_args(argc, argv, "12", &str, &eol, &limit_v)) {
    case 1:
        eol = rb_str_new("\n", 1);
        break;
    case 2:
        break;
    case 3:
        limit = NUM2LONG(limit_v);
        if (limit < 4) {
            rb_raise(rb_eArgError, "too small line length limit");
        }
        break;
    default:
        break;
    }
    return do_base64(str, eol, limit);
}

static VALUE
b64_encode(self, str)
    VALUE self, str;
{
    return do_base64(str, Qnil, 0);
}

static VALUE
b64_decode(argc, argv, self)
    int argc;
    VALUE *argv;
    VALUE self;
{
    VALUE str, strict;
    char *buf, *bp;
    char *p, *pend;
    long len;
    int a, b, c, d;
    VALUE s;

    if (rb_scan_args(argc, argv, "11", &str, &strict) == 1) {
        strict = Qfalse;
    }

    get_ptrlen(&str, &p, &len);
    pend = p + len;
    bp = buf = ALLOC_N(char, (len/4 + 1) * 3);

#define FETCH(ch) \
while (1) {                                                \
    if (p >= pend) goto brk;                               \
    ch = REVTAB[(int)(*p++)];                              \
    if (ch == ILLEGAL) {                                   \
        rb_raise(rb_eArgError, "corrupted base64 string"); \
    }                                                      \
    else if (ch == SKIP) {                                 \
        ;                                                  \
    }                                                      \
    else {                                                 \
        break;                                             \
    }                                                      \
    ch = INIT;                                             \
}
    a = b = c = d = INIT;
    while (p < pend) {
        FETCH(a); D(printf("fetch a: %d\n", (int)a));
        FETCH(b); D(printf("fetch b: %d\n", (int)b));
        FETCH(c); D(printf("fetch c: %d\n", (int)c));
        FETCH(d); D(printf("fetch d: %d\n", (int)d));

        *bp++ = (a << 2) | (b >> 4);
        *bp++ = (b << 4) | (c >> 2);
        *bp++ = (c << 6) | d;
        a = b = c = d = INIT;
    }
brk:
    if (a != INIT && b != INIT && c != INIT) {
        D(puts("3bytes"));
        *bp++ = (a << 2) | (b >> 4);
        *bp++ = (b << 4) | (c >> 2);
    }
    else if (a != INIT && b != INIT) {
        D(puts("2bytes"));
        *bp++ = (a << 2) | (b >> 4);
    }
    /* ignore if only 'a' */

    D(printf("decoded len=%d\n", (int)(bp - buf)));
    s = rb_str_new("", 0);
    rb_str_cat(s, buf, bp - buf);
    free(buf);

    return s;
}

static void
initialize_reverse_table()
{
    int i;

    for (i = 0; i < 256; i++) {
        REVTAB[i] = ILLEGAL;
    }
    REVTAB[(int)'='] = SKIP;
    REVTAB[(int)'\r'] = SKIP;
    REVTAB[(int)'\n'] = SKIP;
    for (i = 0; i < 64; i++) {
        REVTAB[(int)CONVTAB[i]] = (char)i;
    }
}

void
Init_base64()
{
    VALUE Base64;

    Base64 = rb_eval_string("module TMail; module Base64; end end; ::TMail::Base64");
    rb_define_module_function(Base64, "folding_encode", b64_fold_encode, -1);
    rb_define_module_function(Base64, "encode", b64_encode, 1);
    rb_define_module_function(Base64, "decode", b64_decode, -1);
    initialize_reverse_table();
}
