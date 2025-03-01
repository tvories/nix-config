# Configuration for my Ender 3 klipper, mainsail, moonraker, and fluidd setup

{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.klipper = {
    user = "root";
    group = "root";
    enable = true;
    logFile = "/var/lib/klipper/klipper.log";
    firmwares = {
      mcu = {
        enable = true;
        # Run klipper-genconf to generate this
        configFile = ./ender.cfg;
        # Serial port connected to the microcontroller
        serial = "/dev/serial/by-id/usb-Klipper_stm32f103xe_33FFDC0530554D3512691543-if00";
      };
    };
    settings = {
      pause_resume = { };
      virtual_sdcard.path = "/var/lib/moonraker/gcodes";
      bltouch = {
        sensor_pin = "^PC14";
        control_pin = "PA1";
        pin_move_time = "0.675";
        # stow_on_each_sample = false;
        # probe_with_touch_mode = false;
        # pin_up_touch_mode_reports_triggered = false;
        pin_up_reports_not_triggered = true;
        speed = 20;
        lift_speed = 200;
        x_offset = -55;
        y_offset = -13;
        z_offset = 1.470;
        samples = 2;
        sample_retract_dist = 3.0;
        samples_tolerance = 0.1;
        samples_tolerance_retries = 4;
      };

      safe_z_home = {
        home_xy_position = "172.5,130.5";
        speed = 50;
        z_hop = 10;
        z_hop_speed = 5;
      };

      bed_mesh = {
        speed = 120;
        horizontal_move_z = 5;
        mesh_min = "15, 30";
        mesh_max = "165, 205";
        probe_count = "5,5";
        algorithm = "bicubic";
      };

      "bed_mesh default" = {
        version = 1;
        points = "
          0.277500, 0.225000, 0.103750, -0.011250, -0.145000
          0.236250, 0.195000, 0.085000, -0.025000, -0.133750
          0.325000, 0.252500, 0.101250, -0.053750, -0.185000
          0.262500, 0.198750, 0.081250, -0.055000, -0.167500
          0.223750, 0.175000, 0.088750, -0.037500, -0.150000
        ";
        x_count = 5;
        y_count = 5;
        mesh_x_pps = 2;
        mesh_y_pps = 2;
        algo = "bicubic";
        tension = 0.2;
        min_x = 15.0;
        max_x = 165.0;
        min_y = 30.0;
        max_y = 205.0;
      };

      stepper_x = {
        step_pin = "PB13";
        dir_pin = "!PB12";
        enable_pin = "!PB14";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PC0";
        position_endstop = 0;
        position_min = -20;
        position_max = 235;
        homing_speed = 50;
      };

      "tmc2209 stepper_x" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 0;
        run_current = 0.580;
        # hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      stepper_y = {
        step_pin = "PB10";
        dir_pin = "!PB2";
        enable_pin = "!PB11";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PC1";
        position_endstop = 0;
        position_min = -8;
        position_max = 235;
        homing_speed = 50;
      };

      "tmc2209 stepper_y" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 2;
        run_current = 0.580;
        # hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      stepper_z = {
        step_pin = "PB0";
        dir_pin = "PC5";
        enable_pin = "!PB1";
        microsteps = 16;
        rotation_distance = 8;
        endstop_pin = "probe:z_virtual_endstop";
        position_max = 250;
        position_min = -3;
        homing_speed = 4;
        second_homing_speed = 1;
        homing_retract_dist = 2.0;
      };

      "tmc2209 stepper_z" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 1;
        run_current = 0.580;
        # hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      extruder = {
        step_pin = "PB3";
        dir_pin = "!PB4";
        enable_pin = "!PD2";
        microsteps = 16;
        rotation_distance = 33.500;
        nozzle_diameter = 0.400;
        filament_diameter = 1.750;
        heater_pin = "PC8";
        sensor_type = "EPCOS 100K B57560G104F";
        sensor_pin = "PA0";
        control = "pid";
        pid_Kp = 21.527;
        pid_Ki = 1.063;
        pid_Kd = 108.982;
        min_temp = 0;
        max_temp = 265;
      };

      "tmc2209 extruder" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 3;
        run_current = 0.650;
        # hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      heater_bed = {
        heater_pin = "PC9";
        sensor_type = "ATC Semitec 104GT-2";
        sensor_pin = "PC3";
        control = "pid";
        pid_Kp = 54.027;
        pid_Ki = 0.770;
        pid_Kd = 948.182;
        min_temp = 0;
        max_temp = 130;
      };

      # "heater_fan controller_fan" = {
      #   pin = "EXP1_8";
      #   heater = "heater_bed";
      #   heater_temp = 45.0;
      # };

      "heater_fan nozzle_cooling_fan" = {
        pin = "PC7";
      };

      fan = {
        pin = "PC6";
      };

      "temperature_sensor raspberry_pi" = {
        sensor_type = "temperature_host";
        min_temp = 10;
        max_temp = 100;
      };

      "firmware_retraction" = {
        retract_length = 1.0;
        retract_speed = 40.0;
        unretract_extra_length = 0.0;
        unretract_speed = 40.0;
      };

      "gcode_macro PAUSE" = {
        description = "Pause the actual running print";
        rename_existing = "PAUSE_BASE";
        gcode = "
        ##### set defaults #####
        {% set x = params.X|default(200) %}
        {% set y = params.Y|default(200) %}
         {% set z = params.Z|default(10)|float %}
        {% set e = params.E|default(5) %}
        ##### calculate save lift position #####
        {% set max_z = printer.toolhead.axis_maximum.z|float %}
        {% set act_z = printer.toolhead.position.z|float %}
        {% set lift_z = z|abs %}
        {% if act_z < (max_z - lift_z) %}
            {% set z_safe = lift_z %}
        {% else %}
            {% set z_safe = max_z - act_z %}
        {% endif %}
        ##### end of definitions #####
        PAUSE_BASE
        G91
        {% if printer.extruder.can_extrude|lower == 'true' %}
          G1 E-{e} F2100
        {% else %}
          {action_respond_info(\"Extruder not hot enough\")}
        {% endif %}
        {% if \"xyz\" in printer.toolhead.homed_axes %}
          G1 Z{z_safe}
          G90
          G1 X{x} Y{y} F6000
        {% else %}
          {action_respond_info(\"Printer not homed\")}
        {% endif %}
        ";
      };
      "gcode_macro RESUME" = {
        description = "Resume the actual running print";
        rename_existing = "RESUME_BASE";
        gcode = "
        ##### set defaults #####
        {% set e = params.E|default(5) %}
        #### get VELOCITY parameter if specified ####
        {% if 'VELOCITY' in params|upper %}
            {% set get_params = ('VELOCITY=' + params.VELOCITY)  %}
        {%else %}
            {% set get_params = \" \" %}
        {% endif %}
        ##### end of definitions #####
        G91
        {% if printer.extruder.can_extrude|lower == 'true' %}
            G1 E{e} F2100
        {% else %}
            {action_respond_info(\"Extruder not hot enough\")}
        {% endif %}  
        RESUME_BASE {get_params}
        ";
      };
      "gcode_macro START_PRINT" = {
        gcode = "
          {% set BED_TEMP = params.BED_TEMP|default(60)|float %}
          {% set EXTRUDER_TEMP = params.EXTRUDER_TEMP|default(190)|float %}
          # Start bed heating
          M140 S{BED_TEMP}
          # Use absolute coordinates
          G90
          # Reset the G-Code Z offset (adjust Z offset if needed)
          SET_GCODE_OFFSET Z=0.0
          # Home the printer
          G28
          # Move the nozzle near the bed
          G1 Z5 F3000
          # Move the nozzle very close to the bed
          G1 Z0.15 F300
          # Wait for bed to reach temperature
          M190 S{BED_TEMP}
          # Set and wait for nozzle to reach temperature
          M109 S{EXTRUDER_TEMP}
        ";
      };

      "gcode_macro END_PRINT" = {
        gcode = "
          # Turn off bed, extruder, and fan
          M140 S0
          M104 S0
          M106 S0
          # Move nozzle away from print while retracting
          G91
          G1 X-2 Y-2 E-3 F300
          # Raise nozzle by 10mm
          G1 Z10 F3000
          G90
          # Disable steppers
          M84";
      };

      "gcode_macro CANCEL_PRINT" = {
        description = "Cancel the actual running print";
        rename_existing = "CANCEL_PRINT_BASE";
        gcode = "
        TURN_OFF_HEATERS
        CANCEL_PRINT_BASE
        ";
      };

      "gcode_macro M600" = {
        description = "Filament change";
        gcode = "
        {% set X = params.X|default(50)|float %}
        {% set Y = params.Y|default(0)|float %}
        {% set Z = params.Z|default(10)|float %}
        SAVE_GCODE_STATE NAME=M600_state
        PAUSE
        _SOUND_ALARM
        SET_IDLE_TIMEOUT TIMEOUT=28800
        G91
        G1 E-.8 F2700
        G1 Z{Z}
        G90
        G1 X{X} Y{Y} F3000
        G91
        G1 E-50 F1000
        RESTORE_GCODE_STATE NAME=M600_state
        ";
      };

      "gcode_macro idle_timeout" = {
        gcode = "
        timeout: 28800
        ";
      };
      # "gcode_macro _CLIENT_VARIABLE" = {
      #   variable_use_custom_pos = false; # use custom park coordinates for x,y [True/False]
      #   variable_custom_park_x = 0.0; # custom x position; value must be within your defined min and max of X
      #   variable_custom_park_y = 0.0; # custom y position; value must be within your defined min and max of Y
      #   variable_custom_park_dz = 2.0; # custom dz value; the value in mm to lift the nozzle when move to park position
      #   variable_retract = 1.0; # the value to retract while PAUSE
      #   variable_cancel_retract = 5.0; # the value to retract while CANCEL_PRINT
      #   variable_speed_retract = 35.0; # retract speed in mm/s
      #   variable_unretract = 1.0; # the value to unretract while RESUME
      #   variable_speed_unretract = 35.0; # unretract speed in mm/s
      #   variable_speed_hop = 15.0; # z move speed in mm/s
      #   variable_speed_move = 100.0; # move speed in mm/s
      #   variable_park_at_cancel = false; # allow to move the toolhead to park while execute CANCEL_PRINT [True/False]
      #   variable_park_at_cancel_x = null; # different park position during CANCEL_PRINT [None/Position as Float]; park_at_cancel must be True
      #   variable_park_at_cancel_y = null; # different park position during CANCEL_PRINT [None/Position as Float]; park_at_cancel must be True
      #   # !!! Caution [firmware_retraction] must be defined in the printer.cfg if you set use_fw_retract: True !!!
      #   variable_use_fw_retract = false; # use fw_retraction instead of the manual version [True/False]
      #   variable_idle_timeout = 0; # time in sec until idle_timeout kicks in. Value 0 means that no value will be set or restored
      #   variable_runout_sensor = ""; # If a sensor is defined, it will be used to cancel the execution of RESUME in case no filament is detected.
      #   # Specify the config name of the runout sensor e.g "filament_switch_sensor runout". Hint use the same as in your printer.cfg
      #   # !!! Custom macros, please use with care and review the section of the corresponding macro.
      #   # These macros are for simple operations like setting a status LED. Please make sure your macro does not interfere with the basic macro functions.
      #   # Only single line commands are supported, please create a macro if you need more than one command.
      #   variable_user_pause_macro = ""; # Everything inside the "" will be executed after the klipper base pause (PAUSE_BASE) function
      #   variable_user_resume_macro = ""; # Everything inside the "" will be executed before the klipper base resume (RESUME_BASE) function
      #   variable_user_cancel_macro = ""; # Everything inside the "" will be executed before the klipper base cancel (CANCEL_PRINT_BASE) function
      #   gcode = "";
      # };

      mcu = {
        serial = "/dev/serial/by-id/usb-Klipper_stm32f103xe_33FFDC0530554D3512691543-if00";
      };

      printer = {
        kinematics = "cartesian";
        max_velocity = 300;
        max_accel = 3000;
        max_z_velocity = 5;
        max_z_accel = 100;
      };

      force_move = {
        enable_force_move = true;
      };

      board_pins = {
        aliases = "
          EXP1_1=PB5,  EXP1_3=PA9,   EXP1_5=PA10, EXP1_7=PB8,  EXP1_9=<GND>,
          EXP1_2=PA15, EXP1_4=<RST>, EXP1_6=PB9,  EXP1_8=PB15, EXP1_10=<5V>
        ";
      };
      display = {
        lcd_type = "st7920";
        cs_pin = "EXP1_7";
        sclk_pin = "EXP1_6";
        sid_pin = "EXP1_8";
        encoder_pins = "^EXP1_5, ^EXP1_3";
        click_pin = "^!EXP1_2";
      };

      # stock ender display
      # display = {
      #   lcd_type = "st7920";
      #   cs_pin = "PA3";
      #   sclk_pin = "PA1";
      #   sid_pin = "PC1";
      #   encoder_pins = "^PD2, ^PD3";
      #   click_pin = "^!PC0";
      # };

      "output_pin beeper" = {
        pin = "PB5";
      };
    };
  };

  services.moonraker = {
    user = "root";
    enable = true;
    address = "0.0.0.0";
    settings = {
      "power ender3" = {
        type = "tplink_smartplug";
        on_when_job_queued = true;
        #   If set to True the device will power on if a job is queued while the
        #   device is off.  This allows for an automated "upload, power on, and
        #   print" approach directly from the slicer, see the configuration example
        #   below for details. The default is False.
        locked_while_printing = true;
        #   If True, locks the device so that the power cannot be changed while the
        #   printer is printing. This is useful to avert an accidental shutdown to
        #   the printer's power.  The default is False.
        restart_klipper_when_powered = true;
        #   If set to True, Moonraker will schedule a "FIRMWARE_RESTART" to command
        #   after the device has been powered on. If it isn't possible to immediately
        #   schedule a firmware restart (ie: Klippy is disconnected), the restart
        #   will be postponed until Klippy reconnects and reports that startup is
        #   complete.  Prior to scheduling the restart command the power device will
        #   always check Klippy's state.  If Klippy reports that it is "ready", the
        #   FIRMWARE_RESTART will be aborted as unnecessary.
        #   The default is False.
        # restart_delay: 1.
        #   If "restart_klipper_when_powered" is set, this option specifies the amount
        #   of time (in seconds) to delay the restart.  Default is 1 second.
        address = "192.168.1.204";
      };

      "webcam ender" = {
        location = "ender";
        service = "mjpegstreamer";
        target_fps = 30;
        target_fps_idle = 5;
        stream_url = "http://enderpi.mcbadass.local:8080/stream";
        snapshot_url = "http://enderpi.mcbadass.local:8080/snapshot";
        # flip_horizontal: False
        # flip_vertical: False
        # aspect_ratio: 4:3
      };

      octoprint_compat = { };
      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [
          "*.mcbadass.local"
          "*://fluidd.t-vo.us"
        ];
        trusted_clients = [
          "10.0.0.0/8"
          "127.0.0.0/8"
          "169.254.0.0/16"
          "172.16.0.0/12"
          "192.168.1.0/24"
          "FE80::/10"
          "::1/128"
        ];
      };
    };
  };

  services.fluidd = {
    enable = true;
    # nginx.locations."/webcam".proxyPass = "http://127.0.0.1:8080/?action=stream";
  };
  services.nginx.clientMaxBodySize = "1000m";

  # services.mainsail = {
  #   enable = true;
  # };

  systemd.services.ustreamer = {
    # --format=uyvy \ # Device input format
    # --workers=3 \ # Workers number
    #  --dv-timings \ # Use DV-timings
    wantedBy = [ "multi-user.target" ];
    description = "uStreamer for video0";
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.ustreamer}/bin/ustreamer \
        --encoder=HW \
        --persistent \
        --drop-same-frames=30 \
        --host=0.0.0.0 \
        --port=8080
      '';
    };
  };

  # services.mjpg-streamer = {
  #   enable = true;
  # };
}
