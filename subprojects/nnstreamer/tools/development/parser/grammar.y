%{
/* SPDX-License-Identifier: LGPL-2.1-only */
/**
 * This is imported from GStreamer and altered to parse GST-Pipeline
 */

#include <glib-object.h>
#include <glib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "types.h"

/* All error messages in this file are user-visible and need to be translated.
 * Don't start the message with a capital, and don't end them with a period,
 * as they will be presented inside a sentence/error.
 */

#define YYERROR_VERBOSE 1

#define YYENABLE_NLS 0

#ifndef YYLTYPE_IS_TRIVIAL
#define YYLTYPE_IS_TRIVIAL 0
#endif

/*******************************************************************************************
*** define SET_ERROR macro/function
*******************************************************************************************/
#ifdef G_HAVE_ISO_VARARGS

#  define SET_ERROR(error, type, ...) \
G_STMT_START { \
  g_critical (__VA_ARGS__); \
  if ((error) && !*(error)) { \
    g_set_error ((error), GST2PBTXT_PARSE_ERROR, (type), __VA_ARGS__); \
  } \
} G_STMT_END

#elif defined(G_HAVE_GNUC_VARARGS)

#  define SET_ERROR(error, type, args...) \
G_STMT_START { \
  g_critical (args ); \
  if ((error) && !*(error)) { \
    g_set_error ((error), GST2PBTXT_PARSE_ERROR, (type), args ); \
  } \
} G_STMT_END

#else

static inline void
SET_ERROR (GError **error, gint type, const char *format, ...)
{
  if (error) {
    if (*error) {
      g_warning ("error while parsing");
    } else {
      va_list varargs;
      char *string;

      va_start (varargs, format);
      string = g_strdup_vprintf (format, varargs);
      va_end (varargs);

      g_set_error (error, GST2PBTXT_PARSE_ERROR, type, string);

      g_free (string);
    }
  }
}

#endif /* G_HAVE_ISO_VARARGS */

/*** define YYPRINTF macro/function if we're debugging */

/* bison 1.35 calls this macro with side effects, we need to make sure the
   side effects work - crappy bison */

#ifndef GST_DISABLE_GST_DEBUG
#  define YYDEBUG 1

#  ifdef G_HAVE_ISO_VARARGS

#    define YYFPRINTF(a, ...) \
G_STMT_START { \
     g_debug (__VA_ARGS__); \
} G_STMT_END

#  elif defined(G_HAVE_GNUC_VARARGS)

#    define YYFPRINTF(a, args...) \
G_STMT_START { \
     g_debug (args); \
} G_STMT_END

#  else

static inline void
YYPRINTF(const char *format, ...)
{
  va_list varargs;
  gchar *temp;

  va_start (varargs, format);
  temp = g_strdup_vprintf (format, varargs);
  g_debug ("%s", temp);
  g_free (temp);
  va_end (varargs);
}

#  endif /* G_HAVE_ISO_VARARGS */

#endif /* GST_DISABLE_GST_DEBUG */


/*
 * include headers generated by bison & flex, after defining (or not defining) YYDEBUG
 */
#include "grammar.tab.h"
#include "parse_lex.h"

/*******************************************************************************************
*** report missing elements/bins/..
*******************************************************************************************/


static void  add_missing_element(graph_t *graph,gchar *name){
  if ((graph)->ctx){
    (graph)->ctx->missing_elements = g_list_append ((graph)->ctx->missing_elements, g_strdup (name));
    }
}


/*******************************************************************************************
*** helpers for pipeline-setup
*******************************************************************************************/

#define TRY_SETUP_LINK(l) G_STMT_START { \
   if( (!(l)->src.element) && (!(l)->src.name) ){ \
     SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_LINK, "link has no source [sink=%s@%p]", \
	(l)->sink.name ? (l)->sink.name : "", \
	(l)->sink.element); \
     gst_parse_free_link (l); \
   }else if( (!(l)->sink.element) && (!(l)->sink.name) ){ \
     SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_LINK, "link has no sink [source=%s@%p]", \
	(l)->src.name ? (l)->src.name : "", \
	(l)->src.element); \
     gst_parse_free_link (l); \
   }else{ \
     graph->links = g_slist_append (graph->links, l ); \
   }   \
} G_STMT_END

static int  gst_resolve_reference(reference_t *rr, _Element *pipeline){
  _Element *bin;

  if(rr->element) return  0;  /* already resolved! */
  if(!rr->name)   return -2;  /* no chance! */

  if (__GST_IS_BIN (pipeline)){
    bin = __GST_BIN (pipeline);
    rr->element = nnstparser_bin_get_by_name_recurse_up (bin, rr->name);
  } else {
    rr->element = strcmp (__GST_ELEMENT_NAME (pipeline), rr->name) == 0 ?
            nnstparser_element_ref(pipeline) : NULL;
  }
  if(rr->element) return 0; /* resolved */
  else            return -1; /* not found */
}

static void nnstparser_element_set_property (_Element *element, gchar *key, gchar *value)
{
  /* Assign a "name=value" pair to element */
  if (g_strcmp0 (key, "name") == 0) {
    g_free (element->name);
    element->name = strdup (value);
  }
}

static void nnstparser_element_set (gchar *value, _Element *element, graph_t *graph)
{
  gchar *pos = value;
  (void) graph;

  /* do nothing if assignment is for missing element */
  if (element == NULL)
    goto out;

  /* parse the string, so the property name is null-terminated and pos points
     to the beginning of the value */
  while (!g_ascii_isspace (*pos) && (*pos != '=')) pos++;
  if (*pos == '=') {
    *pos = '\0';
  } else {
    *pos = '\0';
    pos++;
    while (g_ascii_isspace (*pos)) pos++;
  }
  pos++;
  while (g_ascii_isspace (*pos)) pos++;
  /* truncate a string if it is delimited with double quotes */
  if (*pos == '"' && pos[strlen (pos) - 1] == '"') {
    pos++;
    pos[strlen (pos) - 1] = '\0';
  }
  gst_parse_unescape (pos);

  nnstparser_element_set_property (element, value, pos);

out:
  g_free (value);
  return;
}

static void g_free_GFunc (void *ptr, void *user_data)
{
  (void) user_data;
  g_free (ptr);
}

static void gst_parse_free_reference (reference_t *rr)
{
  /** Rephrased for nnst parser */
  if (rr->element)
    rr->element = nnstparser_element_unref (rr->element);
  g_free (rr->name);
  g_slist_foreach (rr->pads, (GFunc) g_free_GFunc, NULL);
  g_slist_free (rr->pads);
}

static void gst_parse_free_link (link_t *link)
{
  gst_parse_free_reference (&(link->src));
  gst_parse_free_reference (&(link->sink));
  g_free (link->caps);
  g_slice_free (link_t, link);
}

static void gst_parse_free_chain (chain_t *ch)
{
  GSList *walk;
  gst_parse_free_reference (&(ch->first));
  gst_parse_free_reference (&(ch->last));
  for(walk=ch->elements;walk;walk=walk->next)
    nnstparser_element_unref (walk->data);
  g_slist_free (ch->elements);
  g_slice_free (chain_t, ch);
}

#define PRETTY_PAD_NAME_FMT "%s %s of %s named %s"
#define PRETTY_PAD_NAME_ARGS(elem, pad_name) \
  (pad_name ? "pad " : "some"), (pad_name ? pad_name : "pad"), \
  elem->element, __GST_STR_NULL (__GST_ELEMENT_NAME (elem))

/*
 * performs a link and frees the struct. src and sink elements must be given
 * return values   0 - link performed
 *                <0 - error
 */
static gint
gst_parse_perform_link (link_t *link, graph_t *graph)
{
  _Element *src = link->src.element;
  _Element *sink = link->sink.element;
  GSList *srcs = link->src.pads;
  GSList *sinks = link->sink.pads;
  (void) graph;

  g_assert (__GST_IS_ELEMENT (src));
  g_assert (__GST_IS_ELEMENT (sink));

  g_debug ("linking " PRETTY_PAD_NAME_FMT " to " PRETTY_PAD_NAME_FMT " (%u/%u)\n",
      PRETTY_PAD_NAME_ARGS (src, link->src.name),
      PRETTY_PAD_NAME_ARGS (sink, link->sink.name),
      g_slist_length (srcs), g_slist_length (sinks));

  if (!srcs || !sinks) {
    gboolean found_one = nnstparser_element_link_pads_filtered (src,
        srcs ? (const gchar *) srcs->data : NULL, sink,
        sinks ? (const gchar *) sinks->data : NULL, link->caps);

    if (found_one) {
      if (!link->all_pads)
        goto success; /* Linked one, and not an all-pads link = we're done */

      /* Try and link more available pads */
      while (nnstparser_element_link_pads_filtered (src,
        srcs ? (const gchar *) srcs->data : NULL, sink,
        sinks ? (const gchar *) sinks->data : NULL, link->caps));
    }
    goto error;
  }
  if (g_slist_length (link->src.pads) != g_slist_length (link->sink.pads)) {
    goto error;
  }
  while (srcs && sinks) {
    const gchar *src_pad = (const gchar *) srcs->data;
    const gchar *sink_pad = (const gchar *) sinks->data;
    srcs = g_slist_next (srcs);
    sinks = g_slist_next (sinks);
    if (nnstparser_element_link_pads_filtered (src, src_pad, sink, sink_pad,
        link->caps)) {
      continue;
    } else {
      goto error;
    }
  }

success:
  gst_parse_free_link (link);
  return 0;

error:
  gst_parse_free_link (link);
  return -1;
}


static int yyerror (void *scanner, graph_t *graph, const char *s);
%}

%union {
    gchar *ss;
    chain_t *cc;
    link_t *ll;
    reference_t rr;
    _Element *ee;
    GSList *pp;
    graph_t *gg;
}

/* No grammar ambiguities expected, FAIL otherwise */
%expect 0

%token <ss> PARSE_URL
%token <ss> IDENTIFIER
%left  <ss> REF PADREF BINREF
%token <ss> ASSIGNMENT
%token <ss> LINK
%token <ss> LINK_ALL

%type <ss> binopener
%type <gg> graph
%type <cc> chain bin chainlist openchain elementary
%type <rr> reference
%type <ll> link
%type <ee> element
%type <pp> morepads pads assignments

%destructor {	g_free ($$);		} <ss>
%destructor {	if($$)
		  gst_parse_free_chain($$);	} <cc>
%destructor {	gst_parse_free_link ($$);	} <ll>
%destructor {	gst_parse_free_reference(&($$));} <rr>
%destructor {	nnstparser_element_unref ($$);		} <ee>
%destructor {	GSList *walk;
		for(walk=$$;walk;walk=walk->next)
		  g_free (walk->data);
		g_slist_free ($$);		} <pp>



%left '(' ')'
%left ','
%right '.'
%left '!' '=' ':'

%lex-param { void *scanner }
%parse-param { void *scanner }
%parse-param { graph_t *graph }
%pure-parser

%start graph
%%

/*************************************************************
* Grammar explanation:
*   _element_s are specified by an identifier of their type.
*   a name can be give in the optional property-assignments
*	coffeeelement
*	fakesrc name=john
*	identity silence=false name=frodo
*   (cont'd)
**************************************************************/
element:	IDENTIFIER     		      { $$ = nnstparser_element_make ($1, NULL);
						if ($$ == NULL) {
						  add_missing_element(graph, $1);
						  SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT, "no element \"%s\"", $1);
						}
						g_free ($1);
                                              }
	|	element ASSIGNMENT	      { nnstparser_element_set ($2, $1, graph);
						$$ = $1;
	                                      }
	;

/*************************************************************
* Grammar explanation: (cont'd)
*   a graph has (pure) _element_s, _bin_s and _link_s.
*   since bins are special elements, bins and elements can
*   be generalized as _elementary_.
*   The construction of _bin_s will be discussed later.
*   (cont'd)
*
**************************************************************/
elementary:
	element				      { $$ = g_slice_new0 (chain_t);
						$$->first.element = $1? nnstparser_element_ref ($1) : NULL;
						$$->last.element = $1? nnstparser_element_ref ($1) : NULL;
						$$->first.name = $$->last.name = NULL;
						$$->first.pads = $$->last.pads = NULL;
						$$->elements = $1 ? g_slist_prepend (NULL, $1) : NULL;
					      }
	| bin				      { $$=$1; }
	;

/*************************************************************
* Grammar explanation: (cont'd)
*   a _chain_ is a list of _elementary_s that have _link_s inbetween
*   which are represented through infix-notation.
*
*	fakesrc ! sometransformation ! fakesink
*
*   every _link_ can be augmented with _pads_.
*
*	coffeesrc .sound ! speakersink
*	multisrc  .movie,ads ! .projector,smallscreen multisink
*
*   and every _link_ can be setup to filter media-types
*	mediasrc ! audio/x-raw, signed=TRUE ! stereosink
*
* User HINT:
*   if the lexer does not recognize your media-type it
*   will make it an element name. that results in errors
*   like
*	NO SUCH ELEMENT: no element audio7x-raw
*   '7' vs. '/' in https://en.wikipedia.org/wiki/QWERTZ
*
* Parsing HINT:
*   in the parser we need to differ between chains that can
*   be extended by more elementaries (_openchain_) and others
*   that are syntactically closed (handled later in this file).
*	(e.g. fakesrc ! sinkreferencename.padname)
**************************************************************/
chain:	openchain			      { $$=$1;
						if($$->last.name){
							SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_SYNTAX,
							"unexpected reference \"%s\" - ignoring", $$->last.name);
							g_free ($$->last.name);
							$$->last.name=NULL;
						}
						if($$->last.pads){
							SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_SYNTAX,
							"unexpected pad-reference \"%s\" - ignoring", (gchar*)$$->last.pads->data);
							g_slist_foreach ($$->last.pads, (GFunc) g_free_GFunc, NULL);
							g_slist_free ($$->last.pads);
							$$->last.pads=NULL;
						}
					      }
	;

openchain:
	elementary pads			      { $$=$1;
						$$->last.pads = g_slist_concat ($$->last.pads, $2);
					      }
	| openchain link pads elementary pads
					      {
						$2->src  = $1->last;
						$2->sink = $4->first;
						$2->sink.pads = g_slist_concat ($3, $2->sink.pads);
						TRY_SETUP_LINK($2);
						$4->first = $1->first;
						$4->elements = g_slist_concat ($1->elements, $4->elements);
						g_slice_free (chain_t, $1);
						$$ = $4;
						$$->last.pads = g_slist_concat ($$->last.pads, $5);
					      }
	;

link:	LINK				      { $$ = g_slice_new0 (link_t);
						$$->all_pads = FALSE;
						if ($1) {
						  $$->caps = g_strdup ($1);
						  g_free ($1);
						}
					      }
	| LINK_ALL		              { $$ = g_slice_new0 (link_t);
						$$->all_pads = TRUE;
						if ($1) {
						  $$->caps = g_strdup ($1);
						  g_free ($1);
						}
					      }
	;
pads:		/* NOP */		      { $$ = NULL; }
	|	PADREF morepads		      { $$ = $2;
						$$ = g_slist_prepend ($$, $1);
					      }
	;
morepads:	/* NOP */		      { $$ = NULL; }
	|	',' IDENTIFIER morepads	      { $$ = g_slist_prepend ($3, $2); }
	;

/*************************************************************
* Grammar explanation: (cont'd)
*   the first and last elements of a _chain_ can be give
*   as URL. This creates special elements that fit the URL.
*
*	fakesrc ! http://fake-sink.org
*       http://somesource.org ! fakesink
**************************************************************/

chain:	openchain link PARSE_URL	      { _Element *element =
							  nnstparser_element_from_uri (GST_URI_SINK, $3, NULL, NULL);
						$$ = $1;
						$2->sink.element = element ? nnstparser_element_ref (element) : NULL;
						$2->src = $1->last;
						TRY_SETUP_LINK($2);
						$$->last.element = NULL;
						$$->last.name = NULL;
						$$->last.pads = NULL;
						if(element) $$->elements = g_slist_append ($$->elements, element);
						g_free ($3);
					      }
	;
openchain:
	PARSE_URL			      { _Element *element =
							  nnstparser_element_from_uri (GST_URI_SRC, $1, NULL, NULL);
						$$ = g_slice_new0 (chain_t);
						$$->first.element = NULL;
						$$->first.name = NULL;
						$$->first.pads = NULL;
						$$->last.element = element ? nnstparser_element_ref(element):NULL;
						$$->last.name = NULL;
						$$->last.pads = NULL;
						$$->elements = g_slist_prepend (NULL, element);
						g_free($1);
					      }
	;


/*************************************************************
* Grammar explanation: (cont'd)
*   the first and last elements of a _chain_ can be linked
*   to a named _reference_ (with optional pads).
*
*	fakesrc ! nameOfSinkElement.
*	fakesrc ! nameOfSinkElement.Padname
*	fakesrc ! nameOfSinkElement.Padname, anotherPad
*	nameOfSource.Padname ! fakesink
**************************************************************/

chain:	openchain link reference	      { $$ = $1;
						$2->sink= $3;
						$2->src = $1->last;
						TRY_SETUP_LINK($2);
						$$->last.element = NULL;
						$$->last.name = NULL;
						$$->last.pads = NULL;
					      }
	;


openchain:
	reference 			      { $$ = g_slice_new0 (chain_t);
						$$->last=$1;
						$$->first.element = NULL;
						$$->first.name = NULL;
						$$->first.pads = NULL;
						$$->elements = NULL;
					      }
	;
reference:	REF morepads		      {
						gchar *padname = $1;
						GSList *pads = $2;
						if (padname) {
						  while (*padname != '.') padname++;
						  *padname = '\0';
						  padname++;
						  if (*padname != '\0')
						    pads = g_slist_prepend (pads, g_strdup (padname));
						}
						$$.element=NULL;
						$$.name=$1;
						$$.pads=pads;
					      }
	;


/*************************************************************
* Grammar explanation: (cont'd)
*   a _chainlist_ is just a list of _chain_s.
*
*   You can specify _link_s with named
*   _reference_ on each side. That
*   works already after the explanations above.
*	someSourceName.Pad ! someSinkName.
*	someSourceName.Pad,anotherPad ! someSinkName.Apad,Bpad
*
*   If a syntax error occurs, the already finished _chain_s
*   and _links_ are kept intact.
*************************************************************/

chainlist: /* NOP */			      { $$ = NULL; }
	| chainlist chain		      { if ($1){
						  gst_parse_free_reference(&($1->last));
						  gst_parse_free_reference(&($2->first));
						  $2->first = $1->first;
						  $2->elements = g_slist_concat ($1->elements, $2->elements);
						  g_slice_free (chain_t, $1);
						}
						$$ = $2;
					      }
	| chainlist error		      { $$=$1;
						g_debug ("trying to recover from syntax error");
						SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_SYNTAX, "syntax error");
					      }
	;

/*************************************************************
* Grammar explanation: (cont'd)
*   _bins_
*************************************************************/


assignments:	/* NOP */		      { $$ = NULL; }
	|	ASSIGNMENT assignments 	      { $$ = g_slist_prepend ($2, $1); }
	;

binopener:	'('			      { $$ = g_strdup("bin"); }
	|	BINREF			      { $$ = $1; }
	;
bin:	binopener assignments chainlist ')'   {
						chain_t *chain = $3;
						GSList *walk;
						_Element *bin = nnstparser_gstbin_make ($1, NULL);
						if (!chain) {
						  SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_EMPTY_BIN,
						    "specified empty bin \"%s\", not allowed", $1);
						  chain = g_slice_new0 (chain_t);
						  chain->first.element = chain->last.element = NULL;
						  chain->first.name    = chain->last.name    = NULL;
						  chain->first.pads    = chain->last.pads    = NULL;
						  chain->elements = NULL;
						}
						if (!bin) {
						  add_missing_element(graph, $1);
						  SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT,
						    "no bin \"%s\", unpacking elements", $1);
						  /* clear property-list */
						  g_slist_foreach ($2, (GFunc) g_free_GFunc, NULL);
						  g_slist_free ($2);
						  $2 = NULL;
						} else {
						  /**
						   * Appending multiple elements to slist is inefficient.
						   * Prepend all elements and to reverse.
						   */
						  for (walk = chain->elements; walk; walk = walk->next )
						    bin->elements = g_slist_prepend (bin->elements, walk->data);
						  bin->elements = g_slist_reverse (bin->elements);
						  g_slist_free (chain->elements);
						  chain->elements = g_slist_prepend (NULL, bin);
						}
						$$ = chain;
						/* set the properties now
						 * HINT: property-list cleared above, if bin==NULL
						 */
						for (walk = $2; walk; walk = walk->next)
						  nnstparser_element_set ((gchar *) walk->data,
							bin, graph);
						g_slist_free ($2);
						g_free ($1);
					      }
	;

/*************************************************************
* Grammar explanation: (cont'd)
*   _graph_
*************************************************************/

graph:	chainlist			      { $$ = graph;
						$$->chain = $1;
						if(!$1) {
						  SET_ERROR (graph->error, GST2PBTXT_PARSE_ERROR_EMPTY, "empty pipeline not allowed");
						}
					      }
	;

%%


static int
yyerror (void *scanner, graph_t *graph, const char *s)
{
  (void) scanner;
  (void) graph;
  /* FIXME: This should go into the GError somehow, but how? */
  g_warning ("Error during parsing: %s", s);
  return -1;
}

static void gst_parse_free_link_GFunc (void *ptr, void *user_data)
{
  (void) user_data;
  gst_parse_free_link (ptr);
}

_Element *
priv_gst_parse_launch (const gchar *str, GError **error, _ParseContext *ctx,
    _ParseFlags flags)
{
  graph_t g;
  gchar *dstr;
  GSList *walk;
  _Element *bin = NULL;
  _Element *ret;
  yyscan_t scanner;

  g_return_val_if_fail (str != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  g.chain = NULL;
  g.links = NULL;
  g.error = error;
  g.ctx = ctx;
  g.flags = flags;

  dstr = g_strdup (str);
  priv_gst_parse_yylex_init (&scanner);
  priv_gst_parse_yy_scan_string (dstr, scanner);

#if YYDEBUG
  yydebug = 1;
#endif

  g_debug ("The given string: %s\n", str);

  if (yyparse (scanner, &g) != 0) {
    SET_ERROR (error, GST2PBTXT_PARSE_ERROR_SYNTAX,
        "Unrecoverable syntax error while parsing pipeline %s", str);

    priv_gst_parse_yylex_destroy (scanner);
    g_free (dstr);

    goto error1;
  }
  priv_gst_parse_yylex_destroy (scanner);
  g_free (dstr);

  g_debug ("got %u elements and %u links\n",
      g.chain ? g_slist_length (g.chain->elements) : 0,
      g_slist_length (g.links));

  /* ensure chain is not NULL */
  if (!g.chain) {
    g.chain = g_slice_new0 (chain_t);
    g.chain->elements = NULL;
    g.chain->first.element = NULL;
    g.chain->first.name = NULL;
    g.chain->first.pads = NULL;
    g.chain->last.element = NULL;
    g.chain->last.name = NULL;
    g.chain->last.pads = NULL;
  }

  /* ensure elements is not empty */
  if (!g.chain->elements) {
    g.chain->elements = g_slist_prepend (NULL, NULL);
  };

  /* put all elements in our bin if necessary */
  if (g.chain->elements->next) {
    bin = __GST_BIN_CAST (nnstparser_gstbin_make ("pipeline", NULL));
    g_assert (bin);

    for (walk = g.chain->elements; walk; walk = walk->next) {
      if (walk->data != NULL)
        nnstparser_bin_add (bin, __GST_ELEMENT_CAST (walk->data));
    }
    g_slist_free (g.chain->elements);
    g.chain->elements = g_slist_prepend (NULL, bin);
  }

  ret = (_Element *) g.chain->elements->data;
  g_slist_free (g.chain->elements);
  g.chain->elements = NULL;
  if (__GST_IS_BIN (ret))
    bin = __GST_BIN (ret);
  gst_parse_free_chain (g.chain);
  g.chain = NULL;

  /* resolve and perform links */
  for (walk = g.links; walk; walk = walk->next) {
    link_t *l = (link_t *) walk->data;
    int err;

    err = gst_resolve_reference( &(l->src), ret);
    if (err) {
       if (-1 == err){
          SET_ERROR (error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT,
              "No src-element named \"%s\" - omitting link", l->src.name);
       } else {
          /* probably a missing element which we've handled already */
          SET_ERROR (error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT,
              "No src-element found - omitting link");
       }
       gst_parse_free_link (l);
       continue;
    }

    err = gst_resolve_reference( &(l->sink), ret);
    if (err) {
       if(-1 == err){
          SET_ERROR (error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT,
              "No sink-element named \"%s\" - omitting link", l->src.name);
       } else {
          /* probably a missing element which we've handled already */
          SET_ERROR (error, GST2PBTXT_PARSE_ERROR_NO_SUCH_ELEMENT,
              "No sink-element found - omitting link");
       }
       gst_parse_free_link (l);
       continue;
    }
    gst_parse_perform_link (l, &g);
  }
  g_slist_free (g.links);

out:
  return ret;

error1:
  if (g.chain) {
    gst_parse_free_chain (g.chain);
    g.chain=NULL;
  }

  g_slist_foreach (g.links, (GFunc)gst_parse_free_link_GFunc, NULL);
  g_slist_free (g.links);

  if (error)
    g_assert (*error);
  ret = NULL;

  goto out;
}