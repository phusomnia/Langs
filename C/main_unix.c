#include <stdio.h>
#include "logger.h"

int main(void)
{
    log_msg(LOG_INFO, "Server started on port %d", 8080);
}

