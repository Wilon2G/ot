
#ifndef CONFIG_H
#define CONFIG_H

#define CONFIG_FILE "/etc/ot.conf.json"
#define TERMINAL_HARD_LIMIT 50
#define SPLIT_PATTERN_LIST ['g', 'v', 'h']

#define DEFAULT_VERBOSE false
#define DEFAULT_LOG_FILE "/var/log/ot.log"
//Supported patterns --> grid(g), horizontal(h), vertical(v)
#define DEFAULT_SPLIT_PATTERN 'g'
#define DEFAULT_TERMINAL_LIMIT 100
#define DEFAULT_TERMINAL_EXTRA_TITLE ""
#define DEFAULT_TERMINATOR_PROFILE "default"
#define DEFAULT_JOIN_OPEN false
#define DEFAULT_USER "root"
#define DEFAULT_PASS ""
#define DEFAULT_AUTOCOMPLETE_IP ""
#define DEFAULT_AUTO_AUTHENTICATE true

// -- Operational and command modes --
// Modes --> 0, 1, 2
#define DEFAULT_OPER_MODE 0
#define DEFAULT_WIRESHARK_MODE false

// -- Non-config params --
#define DEFAULT_SHOW_ALL false
#define DEFAULT_AVAILABLE_VMS ""
#define DEFAULT_VM_IPS [NULL]

typedef enum {
    DEFAULT,
    AUTOCOMPLETE_IP,
    SEE_AND_SELECT
} Oper_mode;


typedef struct {
    char    pretty_name[100];
    bool    default_val;
    bool    current_val;
} Verbose_config;

typedef struct {
    char    pretty_name[100];
    char    default_val[100];
    char    current_val[100];
} Log_file_config;


#endif
