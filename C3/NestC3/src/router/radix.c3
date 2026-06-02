module router::radix;

import router::route;
import http::types;

enum SegmentType
{
    STATIC,
    PARAM,
    PARAM_OPT,
    WILDCARD,
    GLOB,
}

struct Node
{
    String part;
    SegmentType type;
    String key;
    String constraint;
    sz[32] children;
    sz children_count;
    types::HttpMethod method;
    route::HandlerFn handler;
    bool has_handler;
}

enum FsmState
{
    START,
    LITERAL,
    ESCAPE,
    QUANTIFIER_CHECK,
    DOT,
    ACCEPT,
    REJECT
}

enum CharClass
{
    DIGIT,
    WORD,
    SPACE,
    LITERAL_CHAR,
    ANY
}

struct FsmContext
{
    int seg_idx;
    int pat_idx;
    FsmState state;
    CharClass char_class;
    char literal_char;
    int quantifier_mode;
}

fn bool is_digit_char(char c)
{
    return c >= '0' && c <= '9';
}

fn bool is_word_char(char c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
}

fn bool is_space_char(char c)
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

fn bool match_char_class(CharClass cls, char c)
{
    switch (cls)
    {
        case CharClass.DIGIT: return is_digit_char(c);
        case CharClass.WORD: return is_word_char(c);
        case CharClass.SPACE: return is_space_char(c);
        case CharClass.LITERAL_CHAR: return true;
        case CharClass.ANY: return true;
        default: return false;
    }
}

fn bool fsm_transition(FsmContext* ctx, String seg, String pat)
{
    switch (ctx.state)
    {
        case FsmState.START:
            if (ctx.pat_idx >= (int)pat.len)
            {
                ctx.state = ctx.seg_idx >= (int)seg.len ? FsmState.ACCEPT : FsmState.REJECT;
                return ctx.state == FsmState.ACCEPT;
            }
            
            if (pat[ctx.pat_idx] == '\\' && ctx.pat_idx + 1 < (int)pat.len)
            {
                ctx.state = FsmState.ESCAPE;
                ctx.pat_idx++;
                return true;
            }
            else if (pat[ctx.pat_idx] == '.')
            {
                ctx.state = FsmState.DOT;
                ctx.pat_idx++;
                return true;
            }
            else if (pat[ctx.pat_idx] == '?' || pat[ctx.pat_idx] == '*' || pat[ctx.pat_idx] == '+')
            {
                ctx.state = FsmState.QUANTIFIER_CHECK;
                return true;
            }
            else
            {
                ctx.state = FsmState.LITERAL;
                ctx.literal_char = pat[ctx.pat_idx];
                ctx.char_class = CharClass.LITERAL_CHAR;
                ctx.pat_idx++;
                return true;
            }

        case FsmState.ESCAPE:
            if (ctx.pat_idx >= (int)pat.len)
            {
                ctx.state = FsmState.REJECT;
                return false;
            }
            
            char esc = pat[ctx.pat_idx];
            ctx.pat_idx++;
            
            if (esc == 'd')
            {
                ctx.char_class = CharClass.DIGIT;
            }
            else if (esc == 'w')
            {
                ctx.char_class = CharClass.WORD;
            }
            else if (esc == 's')
            {
                ctx.char_class = CharClass.SPACE;
            }
            else
            {
                ctx.char_class = CharClass.LITERAL_CHAR;
                ctx.literal_char = esc;
            }
            
            ctx.state = FsmState.QUANTIFIER_CHECK;
            return true;

        case FsmState.LITERAL:
            if (ctx.seg_idx >= (int)seg.len)
            {
                ctx.state = FsmState.REJECT;
                return false;
            }
            
            if (seg[ctx.seg_idx] != ctx.literal_char)
            {
                ctx.state = FsmState.REJECT;
                return false;
            }
            
            ctx.seg_idx++;
            ctx.state = FsmState.QUANTIFIER_CHECK;
            return true;

        case FsmState.DOT:
            if (ctx.seg_idx >= (int)seg.len)
            {
                ctx.state = FsmState.REJECT;
                return false;
            }
            
            ctx.char_class = CharClass.ANY;
            ctx.seg_idx++;
            ctx.state = FsmState.QUANTIFIER_CHECK;
            return true;

        case FsmState.QUANTIFIER_CHECK:
            if (ctx.pat_idx < (int)pat.len)
            {
                char quant = pat[ctx.pat_idx];
                if (quant == '+')
                {
                    ctx.pat_idx++;
                    while (ctx.seg_idx < (int)seg.len && match_char_class(ctx.char_class, seg[ctx.seg_idx]))
                    {
                        if (ctx.char_class == CharClass.LITERAL_CHAR && seg[ctx.seg_idx] != ctx.literal_char)
                        {
                            break;
                        }
                        ctx.seg_idx++;
                    }
                    ctx.state = FsmState.START;
                    return true;
                }
                else if (quant == '*')
                {
                    ctx.pat_idx++;
                    if (ctx.pat_idx >= (int)pat.len)
                    {
                        ctx.state = FsmState.ACCEPT;
                        return true;
                    }
                    ctx.state = FsmState.START;
                    return true;
                }
                else if (quant == '?')
                {
                    ctx.pat_idx++;
                    ctx.state = FsmState.START;
                    return true;
                }
            }
            
            ctx.state = FsmState.START;
            return true;

        case FsmState.ACCEPT:
            return true;

        case FsmState.REJECT:
            return false;

        default:
            ctx.state = FsmState.REJECT;
            return false;
    }
}

fn bool match_constraint(String seg, String pat)
{
    FsmContext ctx;
    ctx.seg_idx = 0;
    ctx.pat_idx = 0;
    ctx.state = FsmState.START;
    ctx.char_class = CharClass.LITERAL_CHAR;
    ctx.literal_char = '\0';
    ctx.quantifier_mode = 0;
    
    while (ctx.state != FsmState.ACCEPT && ctx.state != FsmState.REJECT)
    {
        if (!fsm_transition(&ctx, seg, pat))
        {
            return false;
        }
    }
    
    return ctx.state == FsmState.ACCEPT && ctx.seg_idx == (int)seg.len;
}
