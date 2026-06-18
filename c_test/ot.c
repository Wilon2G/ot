#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <getopt.h>
#include <sys/types.h>

//My logger :)
#include "logger.h"
//My config :)
#include "config.h"

#define TITLE_MAX_CHAR 100

// Config-param
/*
typedef struct {
    char name[100];
    char pretty_name[100];
    --   default_val;
    --   current_val;
} Config_param;
*/

// Config
typedef struct {
    bool    verbose;
    char    log_file[100];
    char    split_pattern;
    int     terminal_limit;
    char    terminal_extra_title[100];
    char    terminator_profile[100];
    bool    join_open;
    char    default_user[100];
    char    default_pass[100];
    char    autocomplete_ip[100];
    bool    auto_authenticate;
    char    *terminals_to_open[TERMINAL_HARD_LIMIT];
    int     terminals_to_open_count;
    int     oper_mode;
    bool    wireshark_mode;
} Config;

int parse_arguments(int argc, char *argv[], Config *config);
int config_check(Config *config);
void open_separate_terminals(Config *config);
void process_title(char terminal[], char terminal_extra_title[], char *title);
void replace_spaces(char *str);

int main(int argc, char *argv[]) {

    Config config ={.verbose = DEFAULT_VERBOSE, 
                    .log_file = DEFAULT_LOG_FILE, 
                    .split_pattern = DEFAULT_SPLIT_PATTERN,
                    .terminal_limit = DEFAULT_TERMINAL_LIMIT,
                    .terminal_extra_title = DEFAULT_TERMINAL_EXTRA_TITLE,
                    .terminator_profile = DEFAULT_TERMINATOR_PROFILE,
                    .join_open = DEFAULT_JOIN_OPEN,
                    .default_user = DEFAULT_USER,
                    .default_pass = DEFAULT_PASS,
                    .autocomplete_ip = DEFAULT_AUTOCOMPLETE_IP,
                    .auto_authenticate = DEFAULT_AUTO_AUTHENTICATE,
                    .terminals_to_open = {NULL},
                    .terminals_to_open_count = 0,
                    .oper_mode = DEFAULT_OPER_MODE,
                    .wireshark_mode = DEFAULT_WIRESHARK_MODE};


    parse_arguments(argc, argv, &config);
    if(!config_check(&config)){
        LOG_ERROR("Configuration Error above");
        return -1;
    }

    switch(config.oper_mode){
        case 0:
            break;
        case 1:
            LOG_INFO("Operational Mode Selected --> Autocomplete IP");
            LOG_INFO("Configured Autocomplte IP --> %s", config.autocomplete_ip);
            break;
        case 2:
            break;
        default:
            break;
    }

    if(config.join_open){
        LOG_INFO("Join open");

    }else{
        LOG_INFO("Terminal mode --> Separate");
        open_separate_terminals(&config);

    }

    /*
    char *args[] = {"echo ", config.title, NULL};
    execvp(args[0], args);
    for (int i = 0; i < config.terminals_to_open; i++) {
        if (fork() == 0) {
            char *args[] = {"terminator", "-T", config.title, NULL};
            execvp(args[0], args);
            exit(1);
        }
    }
    */
    return 0;
}

void replace_spaces(char *str) {
    if (str == NULL) return;
    for (int i = 0; str[i] != '\0'; i++) {
        if (str[i] == ' ') {
            str[i] = '_';
        }
    }
}

void process_title(char terminal[], char terminal_extra_title[], char *title){
    LOG_INFO("Procesing title for terminal --> %s", terminal);
    replace_spaces(terminal_extra_title);

    //bool only_extra = (strcmp(terminal_extra_title[0], "-") == 0);
    bool only_extra = (terminal_extra_title[0] == '-');
    if(only_extra){
        strcpy(title, terminal_extra_title + 1);
    }else{
        //strcpy(title, terminal);
        snprintf(title, TITLE_MAX_CHAR, "%s~%s", terminal_extra_title, terminal);
    }
}

void open_separate_terminals(Config *config){
    for(int i = 0; i < config->terminals_to_open_count ; i++){
        LOG_INFO("Processing terminal %s", config->terminals_to_open[i]);
        char title[TITLE_MAX_CHAR];
        process_title(config->terminals_to_open[i], config->terminal_extra_title, title);
        LOG_INFO("==== ! %s", title);

    }
}

int parse_arguments(int argc, char *argv[], Config *config) {
    // Loop starts at 1 because argv[0] is always the program name
    for (int i = 1; i < argc; i++) {
        
        // function ARGS ---------------------------------------------------------------------
        if (strcmp(argv[i], "-k") == 0 || strcmp(argv[i], "--nickname") == 0) {
            //exec show_nicknames()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }
        else if (strcmp(argv[i], "--test") == 0) {
            //exec test()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }
        else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            //exec help()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }
        else if (strcmp(argv[i], "--see") == 0) {
            //exec see()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }
        else if (strcmp(argv[i], "--see-all") == 0) {
            //exec seeall()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }
        else if (strcmp(argv[i], "-c") == 0 || strcmp(argv[i], "--config") == 0) {
            //exec config()
            LOG_ERROR("[ %s ] not implemented\n", argv[i]);
        }

        // CONFIG CHANGES ARGS -------------------------------------------------------------
        else if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0) {
            config->verbose = true;
        } 
        else if (strcmp(argv[i], "--no-auth") == 0) {
            config->auto_authenticate= false;
        } 
        else if (strcmp(argv[i], "-s") == 0 || strcmp(argv[i], "--split") == 0) {
            config->join_open = false;
        } 
        else if (strcmp(argv[i], "-j") == 0 || strcmp(argv[i], "--join") == 0) {
            config->join_open = true;
        } 
        else if (strcmp(argv[i], "-jv") == 0 || strcmp(argv[i], "--joinv") == 0) {
            config->join_open = true;
            config->split_pattern = 'v';
        } 
        else if (strcmp(argv[i], "-jh") == 0 || strcmp(argv[i], "--joinh") == 0) {
            config->join_open = true;
            config->split_pattern = 'h';
        } 
        else if (strcmp(argv[i], "-jg") == 0 || strcmp(argv[i], "--joing") == 0) {
            config->join_open = true;
            config->split_pattern = 'g';
        } 
        // --- OPER_MODE args ---
        else if (strcmp(argv[i], "-d") == 0 || strcmp(argv[i], "--default") == 0) {
            config->oper_mode = 0;
        } 
        else if (strcmp(argv[i], "-a") == 0 || strcmp(argv[i], "--autocomplete") == 0) {
            config->oper_mode = 1;
        } 
        else if (strcmp(argv[i], "--full-ip") == 0) {
            config->oper_mode = 2;
        } 
        // --- COMMAND MODE ---
        else if (strcmp(argv[i], "-w") == 0) {
            config->wireshark_mode = true;
        } 
        
        // --- Terminal args --- 
        else if (strcmp(argv[i], "-t") == 0 || strcmp(argv[i], "--title") == 0) {
            //mk sure next arg exists
            if (i + 1 < argc) {
                strncpy(config->terminal_extra_title, argv[i + 1], sizeof(config->terminal_extra_title) - 1);
                config->terminal_extra_title[sizeof(config->terminal_extra_title) - 1] = '\0';
                //terminal_extra_title = argv[i + 1];
                i++; // Skip the next index since we just consumed it as a value
            } 
            else {
                LOG_ERROR("[ %s ] requires an argument\n", argv[i]);
            }
        } 
        else if (strcmp(argv[i], "-n") == 0) {
            //Ensure the next 2 argument actually exists 
            if (i + 2 < argc) {
                char *endptr;
                long number_to_add = strtol(argv[i + 1], &endptr, 10);

                if (endptr == argv[i + 1] || *endptr != '\0') {
                    LOG_ERROR("[ %s ] is not a valid number of terminals\n", argv[i]);
                    return 1;
                }        
                if(number_to_add > config->terminal_limit){
                    LOG_WARN("[ %s ] Terminal limit reached, adding %i terminals\n", argv[i], config->terminal_limit);
                    number_to_add = config->terminal_limit;
                }
                for (int j = 0; j < number_to_add; j++) {
                    if(config->terminals_to_open_count < sizeof(config->terminals_to_open)){
                        config->terminals_to_open[config->terminals_to_open_count] = argv[i + 2];
                        config->terminals_to_open_count++;
                    }
                    else{
                        LOG_ERROR("Hard limit of terminals reached\n");
                    }
                }
                i++;
                i++; //skip two
            } else {
                LOG_ERROR("[ %s ] requires 2 arguments\n", argv[i]);
                if(i + 1 < argc){ //If we only pass onearg we skip it
                    i++;
                }
            }
        } 
        else if(strncmp(argv[i], "-", 1) == 0){
            LOG_WARN("Unknown argument '%s' ignored\n", argv[i]);
        }
        else {
            if(config->terminals_to_open_count < sizeof(config->terminals_to_open)){
                config->terminals_to_open[config->terminals_to_open_count] = argv[i];
                config->terminals_to_open_count++;
            }
            else{
                LOG_ERROR("Hard limit of terminals reached\n");
            }
        }
    }
    return 0;
}

//Checks if config is correct
int config_check(Config *config){
    int rc = 1;
    int lvl = 0;
    LOG_INFO("=== Config Check ===");

    LOG((config->verbose != DEFAULT_VERBOSE?2:1), "Verbose --> %b", config->verbose);

    LOG(((strcmp(config->log_file, DEFAULT_LOG_FILE) != 0)?2:1), "Log File --> %s", config->log_file);

    if(config->split_pattern != DEFAULT_SPLIT_PATTERN){
        if(config->split_pattern != 'g' && config->split_pattern != 'h' && config->split_pattern != 'v'){
            lvl = 3;
            rc = -1;
        }else{
            lvl = 2;
        }
    }else{
        lvl = 1;
    }
    LOG(lvl, "Split Pattern --> %c", config->split_pattern);

    if(config->terminal_limit != DEFAULT_TERMINAL_LIMIT){
        if(config->terminal_limit <= 0){
            lvl = 3;
            rc = -1;
        }else{
            lvl = 2;
        }
    }else{
        lvl = 1;
    }
    LOG(lvl, "Terminal Limit --> %i", config->terminal_limit);

    LOG(((strcmp(config->terminal_extra_title, DEFAULT_TERMINAL_EXTRA_TITLE) != 0)?2:1), "Terminal Extra Title --> %s", config->terminal_extra_title);

    LOG(((strcmp(config->terminator_profile, DEFAULT_TERMINATOR_PROFILE) != 0)?2:1), "Terminator profile --> %s", config->terminator_profile);

    LOG(((config->join_open != DEFAULT_JOIN_OPEN)?2:1), "Join Open --> %b", config->join_open);

    LOG(((strcmp(config->default_user, DEFAULT_USER) != 0)?2:1), "Default User --> %s", config->default_user);

    LOG(((strcmp(config->default_pass, DEFAULT_PASS) != 0)?2:1), "Default Password");

    LOG(((strcmp(config->autocomplete_ip, DEFAULT_AUTOCOMPLETE_IP) != 0)?2:1), "Autocomplete_ip --> %s", config->autocomplete_ip);

    LOG(((config->auto_authenticate != DEFAULT_AUTO_AUTHENTICATE)?2:1), "Auto Authenticate --> %b", config->auto_authenticate);

    LOG(((config->terminals_to_open_count >= TERMINAL_HARD_LIMIT)?2:1), "Total Number Of Terminals --> %i", config->terminals_to_open_count);

    //Logging terminals to open ---
    char buffer[1024] = {0};
    int offset = 0;

    offset += snprintf(buffer + offset, sizeof(buffer) - offset, "Terminals To Open --> [ ");

    for (int i = 0; i < config->terminals_to_open_count; i++) {
        offset += snprintf(buffer + offset, sizeof(buffer) - offset, "%s ", config->terminals_to_open[i]);
    }
    snprintf(buffer + offset, sizeof(buffer) - offset, "]");
    LOG_WARN("%s", buffer);

    if(config->oper_mode != 0 && config->oper_mode != 1 && config->oper_mode != 2){
        //LOG_ERROR("UNKNOWN OPERATIONAL MODE --> %i", config->oper_mode);
        lvl = 3;
        rc = -1;
    }else if(config->oper_mode != DEFAULT_OPER_MODE){
        lvl = 2;
    }else{
        lvl = 1;
    }
    LOG(lvl, "Operational Mode --> %i", config->oper_mode);

    LOG(((config->wireshark_mode != DEFAULT_WIRESHARK_MODE)?2:1), "Wireshark Mode --> %b", config->wireshark_mode);

    if((config->oper_mode = 1) && (strcmp(config->autocomplete_ip, "") == 0)){
        LOG_WARN("Operation Mode is set to autocomplete the IP but no Autocomplete IP is set");
    }

    LOG_INFO("=== Config Check Completed ===");
    LOG_INFO("");
    
    return rc;
}













