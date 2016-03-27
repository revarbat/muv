#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "strutils.h"


int
isint(const char *s)
{
    if (!*s) {
        return 0;
    }
    while (*s) {
        if (!isdigit(*s)) {
            return 0;
        }
        s++;
    }
    return 1;
}


int
endswith(const char *s, const char *s2)
{
    return !strcmp(s+strlen(s)-strlen(s2), s2);
}



char *
savestring(const char *arg)
{
    char *tmp = (char *)malloc(strlen(arg) + 1);
    strcpy(tmp, arg);
    return(tmp);
}



char *
appendstr(char *s, ...)
{
    va_list aptr;
    const char *p;
    if (!s) {
        s = savestring("");
    }
    va_start(aptr, s);
    while ((p = va_arg(aptr, const char*))) {
        size_t len1 = strlen(s);
        size_t len2 = strlen(p);
        s = (char*)realloc(s, len1 + len2 + 2);
        len1 = lastlen(s);
        len2 = firstlen(p);
        if (len1 > 0 && len2 > 0) {
            if (len1 + len2 > 60) {
                strcat(&s[len1], "\n");
            } else {
                strcat(&s[len1], " ");
            }
        }
        strcat(&s[len1], p);
    }
    va_end(aptr);
    return s;
}



char *
savefmt(const char *fmt, ...)
{
    va_list aptr;
    size_t buflen = 128;
    char *buf = (char*)malloc(buflen);
    int len;

    va_start(aptr, fmt);
    len = vsnprintf(buf, buflen, fmt, aptr);
    va_end(aptr);

    if (len >= buflen-1) {
        buflen = len + 2;
        buf = (char*)realloc(buf, buflen);
        va_start(aptr, fmt);
        len = vsnprintf(buf, buflen, fmt, aptr);
        va_end(aptr);
    }

    return buf;
}



char *
appendfmt(char *s, const char *fmt, ...)
{
    va_list aptr;
    size_t buflen = 128;
    char *buf = (char*)malloc(buflen);
    int len;

    va_start(aptr, fmt);
    len = vsnprintf(buf, buflen, fmt, aptr);
    va_end(aptr);

    if (len >= buflen-1) {
        buflen = len + 2;
        buf = (char*)realloc(buf, buflen);
        va_start(aptr, fmt);
        len = vsnprintf(buf, buflen, fmt, aptr);
        va_end(aptr);
    }

    s = appendstr(s, buf, NULL);
    free(buf);

    return s;
}



char *
indent(const char *arg)
{
    const int indentlen = 4;
    char *buf;
    const char *ptr;
    char *ptr2;
    int i, lines;

    if (!arg || !*arg) {
        return savestring("");
    }
    for (ptr = arg, lines = 1; *ptr; ptr++) {
        if (*ptr == '\n') {
            lines++;
        }
    }
    buf = (char *)malloc(strlen(arg) + 1 + indentlen*lines);
    ptr = arg;
    ptr2 = buf;
    while (*ptr) {
        for (i = 0; *ptr != '\n' && i < indentlen; i++) {
            *ptr2++ = ' ';
        }
        while (*ptr) {
            *ptr2++ = *ptr;
            if (*ptr++ == '\n') break;
        }
    }
    *ptr2 = '\0';
    return buf;
}



char *
format_muv_str(const char *s)
{
    const char *p;
    char *out;
    char *p2;
    size_t len;
    for (len = 5, p = s; *p; len++, p++) {
        switch (*p) {
            case '\\':
            case '"':
            case '\n':
            case '\r':
            case '\b':
                len++;
                break;
        }
    }
    out = (char*)malloc(len);
    p2 = out;
    *p2++ = '\"';
    for (p = s; *p; p++) {
        switch (*p) {
            case '\\':
            case '\"':
                *p2++ = '\\';
                *p2++ = *p;
                break;
            case '\r':
            case '\n':
                *p2++ = '\\';
                *p2++ = 'r';
                break;
            case '\033':
                *p2++ = '\\';
                *p2++ = '[';
                break;
            default:
                *p2++ = *p;
                break;
        }
    }
    *p2++ = '\"';
    *p2++ = '\0';
    return out;
}


size_t
firstlen(const char *s)
{
    size_t len = 0;
    while (*s) {
        if (*s == '\n') {
            return len;
        } else {
            len++;
        }
        s++;
    }
    return len;
}


size_t
lastlen(const char *s)
{
    size_t len = 0;
    while (*s) {
        if (*s == '\n') {
            len = 0;
        } else {
            len++;
        }
        s++;
    }
    return len;
}


size_t
linecount(const char *s)
{
    size_t len = 1;
    while (*s) {
        if (*s == '\n') {
            len++;
        }
        s++;
    }
    return len;
}


char *
wrapit(const char *pfx, const char *s, const char *sfx)
{
    char *out;
    if (linecount(s) > 1 || strlen(pfx) + strlen(s) + strlen(sfx) > 60) {
        char *ind = indent(s);
        out = savefmt("%s\n%s\n%s", pfx, ind, sfx);
        free(ind);
    } else {
        out = savefmt("%s %s %s", pfx, s, sfx);
    }
    return out;
}


char *
wrapit2(const char *pfx, const char *s, const char *mid, const char *s2, const char *sfx)
{
    char *out;
    if (linecount(s) > 1 || linecount(s2) > 1 || strlen(pfx) + strlen(s) + strlen(mid) + strlen(s2) + strlen(sfx) > 60) {
        char *ind = indent(s);
        char *ind2 = indent(s2);
        out = savefmt("%s\n%s\n%s\n%s\n%s", pfx, ind, mid, ind2, sfx);
        free(ind);
        free(ind2);
    } else {
        out = savefmt("%s %s %s %s %s", pfx, s, mid, s2, sfx);
    }
    return out;
}


char*
wordcpy(char *out, const char *s)
{
    char *p = out;
    while (*s && !isspace(*s)) {
        *p++ = *s++;
    }
    *p++ = '\0';
    return out;
}

size_t
wordlen(const char *s)
{
    size_t len = 0;
    while (*s && !isspace(*s)) {
        len++; s++;
    }
    return len;
}


char *
replace_words(char *txt, const char *pat, const char *repl)
{
    size_t replen = strlen(repl);
    size_t patlen = strlen(pat);
    char *out = (char*)malloc(strlen(txt) + 1 + replen + patlen);
    char *words[10];
    char txtword[1024];
    char patword[1024];
    const char *startpos, *r, *s, *p;
    char *outp;
    int i, wordnum;
    int lastword = 1;
    for (i = 0; i < 10; i++)
        words[i] = NULL;
    while (isspace(*pat)) pat++;
    startpos = txt + strlen(txt);
    while (1) {
        while (startpos >= txt && isspace(*startpos)) startpos--;
        s = startpos;
        p = pat + strlen(pat);
        while(1) {
            s--; p--;
            if (s <= txt) {
                strcpy(out, txt);
                for (i = 0; i < 10; i++)
                    if (words[i])
                        free(words[i]);
                return out;
            }
            while (s >= txt && isspace(*s)) s--;
            while (s >= txt && !isspace(*s)) s--;
            wordcpy(txtword, ++s);

            while (p >= pat && isspace(*p)) p--;
            while (p >= pat && !isspace(*p)) p--;
            wordcpy(patword, ++p);

            if (patword[0] == '%' && isdigit(patword[1]) && !patword[2]) {
                wordnum = patword[1] - '0';
                if (words[wordnum]) {
                    if (strcmp(txtword, words[wordnum])) {
                        break;
                    }
                } else {
                    words[wordnum] = savestring(txtword);
                }
            } else if (strcmp(patword, txtword)) {
                break;
            }
            if (p <= pat) {
                size_t pfxlen = s - txt;
                strncpy(out, txt, pfxlen);
                out[pfxlen] = '\0';
                outp = out+pfxlen;
                r = repl;
                while (*r) {
                    if (*r == '%' && isdigit(r[1])) {
                        r++;
                        wordnum = *r - '0';
                        if (words[wordnum]) {
                            strcpy(outp, words[wordnum]);
                            outp += strlen(outp);
                        }
                        r++;
                    } else {
                        *outp++ = *r++;
                    }
                }
                *outp = '\0';
                if (!lastword) {
                    strcpy(outp, startpos-1);
                }
                for (i = 0; i < 10; i++)
                    if (words[i])
                        free(words[i]);
                return out;
            }
        }
        while (startpos >= txt && !isspace(*startpos)) startpos--;
        lastword = 0;
    }
}


char *
sanitize_path(char* out, size_t outlen, const char *path, const char *cwd)
{
    char *outp = out;
    const char *in;
    int dots = 0;
    if (*path != '/') {
        /* relative path */
        dots = 0;
        for (in = cwd; *in && outp - out < outlen-2; ) {
            if (*in == '/') {
                if (dots > 0) {
                    outp--;
                    while (outp > out && *outp == '.') *outp-- = '\0';
                }
                *outp++ = '/';
                while (*in == '/') in++;
                dots = 0;
                continue;
            }
            if (*in == '.') {
                if (dots >= 0) {
                    dots++;
                }
            } else {
                dots = -1;
            }
            *outp++ = *in++;
        }
        *outp = '\0';
        if (outp > out && outp[-1] == '/') {
            outp--;
            while (outp > out && *outp == '/') *outp-- = '\0';
            if (outp>out) outp++;
        }
        if (cwd && *cwd) {
            *outp++ = '/';
        }
        *outp = '\0';
    }

    dots = 0;
    for (in = path; *in && outp - out < outlen-2; ) {
        if (*in == '/') {
            if (dots > 0) {
                outp--;
                while (outp > out && *outp == '.') *outp-- = '\0';
            }
            *outp++ = '/';
            while (*in == '/') in++;
            dots = 0;
            continue;
        }
        if (*in == '.') {
            if (dots >= 0) {
                dots++;
            }
        } else {
            dots = -1;
        }
        *outp++ = *in++;
    }
    *outp = '\0';
    if (outp > out && outp[-1] == '/') {
        outp--;
        while (outp > out && *outp == '/') *outp-- = '\0';
    }
    return out;
}


void getset_free(accessor *x)
{
    if (x->get) {
        free((char*)x->get);
        x->get = NULL;
    }
    if (x->set) {
        free((char*)x->set);
        x->set = NULL;
    }
    if (x->del) {
        free((char*)x->del);
        x->del = NULL;
    }
    if (x->call) {
        free((char*)x->call);
        x->call = NULL;
    }
    if (x->oper_pre) {
        free((char*)x->oper_pre);
        x->oper_pre = NULL;
    }
    if (x->oper_post) {
        free((char*)x->oper_post);
        x->oper_post = NULL;
    }
}



/* vim: set ts=4 sw=4 et ai hlsearch nowrap : */

