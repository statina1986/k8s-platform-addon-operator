from re import sub
import sys
import traceback


def kebab(s):
    return '-'.join(
        sub(r"(\s|_|-)+", " ",
            sub(r"[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+",
                lambda mo: ' ' + mo.group(0).lower(), s)).split())


def get_exception_string():
    ex_type, ex_value, ex_traceback = sys.exc_info()

    # Extract unformatter stack traces as tuples
    trace_back = traceback.extract_tb(ex_traceback)

    # Format stacktrace
    stack_trace = list()

    for trace in trace_back:
        stack_trace.append("File : %s , Line : %d, Func.Name : %s, Message : %s" % (
            trace[0], trace[1], trace[2], trace[3]))

    return f"{ex_type} : {ex_value}\nStack Trace:\n{stack_trace}"
