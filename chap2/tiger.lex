%{
#include <string.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

int yywrap(void)
{
 charPos=1;
 return 1;
}


void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

int commentNesting = 0;
static char *strbuf;
static int strbuf_size;
static int strbuf_leng;
static void strbuf_init() {
  if(strbuf) free(strbuf);
  strbuf = checked_malloc(32);
  strbuf[0] = '\0';
  strbuf_size = 32;
  strbuf_leng = 0;
}
static void strbuf_pushback(char ch) {
  if (strbuf_leng == strbuf_size) {
    char *tmp = checked_malloc(strbuf_size*=2);
    memcpy(tmp, strbuf, strbuf_leng); free(strbuf);
    strbuf = tmp;
  }
  strbuf[strbuf_leng] = ch;
  strbuf[strbuf_leng+=1] = '\0';
}
%}

space [ \t\r]
id [a-zA-Z][a-zA-Z0-9]* 
number [0-9]+ 
ctrl_char \^[@A-Z\[\\\]\^_\?] 
%x COMMENT_STATE STRING_STATE STRING_ESCAPE_STATE 


%%
{space} {adjust(); printf("");} 


"\n" { adjust(); printf("NL\n");} 




"," { adjust(); printf("comma\n");}
":" { adjust(); printf("colon \n");}
";" { adjust(); printf("semicolon \n");}
"." { adjust(); printf("dot \n");}
"(" { adjust(); printf("lparen \n");}
")" { adjust(); printf("rparen \n");}
"[" { adjust(); printf("lbrack \n");}
"]" { adjust(); printf("rbrack \n");}
"{" { adjust(); printf("lbrace \n");}
"}" { adjust(); printf("rbrace \n");}
"+" { adjust(); printf("plus \n");}
"-" { adjust(); printf("minus \n");}
"*" { adjust(); printf("times \n");}
"/" { adjust(); printf("div \n");}
"&" { adjust(); printf("and \n");}
"|" { adjust(); printf("or \n");}
"=" { adjust(); printf("eq \n");}
"<>" { adjust(); printf("neq \n");}
"<" { adjust(); printf("lt \n");}
"<=" { adjust(); printf("le \n");}
">" { adjust(); printf("gt \n");}
">=" { adjust(); printf("ge \n");}
":=" { adjust(); printf("assign \n");}


for { adjust(); printf("for \n");}
while { adjust(); printf("while \n");}
if { adjust(); printf("if \n");}
then { adjust(); printf("then \n");}
else { adjust(); printf("else \n");}
break { adjust(); printf("break \n");}
to { adjust(); printf("to \n");}
do { adjust(); printf("do \n");}
let { adjust(); printf("let \n");}
in { adjust(); printf("in \n");}
end { adjust(); printf("end \n");}
of { adjust(); printf("of \n");}
var { adjust(); printf("var \n");}
type { adjust(); printf("type \n");}
function { adjust(); printf("function \n");}
array { adjust(); printf("array\n");}
nil { adjust(); printf("nil \n");}


{number} {adjust(); yylval.ival=atoi(yytext); printf("number %d \n",yylval.ival);}
{id} {adjust(); yylval.sval=strdup(yytext); printf("id %s \n",yylval.sval);}


"/*"    {adjust(); ++commentNesting; BEGIN COMMENT_STATE;}
<COMMENT_STATE>"/*"    {adjust(); ++commentNesting; continue;}
<COMMENT_STATE>"*/"    {adjust(); --commentNesting; if(!commentNesting) BEGIN INITIAL;}
<COMMENT_STATE>\n      {adjust(); EM_newline(); continue;}
<COMMENT_STATE><<EOF>> {EM_error(EM_tokPos, "Unterminated comment."); yyterminate();}
<COMMENT_STATE>.       {adjust();}



\"    {adjust(); strbuf_init(); BEGIN STRING_STATE;}
<STRING_STATE>\"      {adjust(); BEGIN INITIAL; yylval.sval = strdup(strbuf); return STRING;}
<STRING_STATE>\n      {adjust(); EM_error(EM_tokPos, "Unterminated string."); yyterminate();}
<STRING_STATE>\\      {adjust(); BEGIN STRING_ESCAPE_STATE;}
<STRING_STATE><<EOF>> {EM_error(EM_tokPos, "Unterminated string."); yyterminate();}
<STRING_STATE>.       {adjust(); strbuf_pushback(*yytext); continue;}

<STRING_ESCAPE_STATE>n           {adjust(); strbuf_pushback('\n'); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>t           {adjust(); strbuf_pushback('\t'); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>{ctrl_char} {adjust(); strbuf_pushback(yytext[1]-'@'); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>[0-9]{3}    {adjust(); strbuf_pushback(atoi(yytext)); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>\"          {adjust(); strbuf_pushback('\"'); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>\\          {adjust(); strbuf_pushback('\\'); BEGIN STRING_STATE;}
<STRING_ESCAPE_STATE>{space}+\\  {adjust();
                                  for(int i = 0; yytext[i]; ++i) 
                                    if (yytext[i] == '\n') EM_newline();
                                   BEGIN STRING_STATE;}


. { adjust(); printf("other \n");} 



