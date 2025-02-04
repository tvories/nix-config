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
        serial = "/dev/serial/by-id/usb-Klipper_stm32g0b1xx_510014000250414235363020-if00";
      };
    };
    settings = {
      pause_resume = { };
      virtual_sdcard.path = "/var/lib/moonraker/gcodes";
      bltouch = {
        sensor_pin = "^PC14";
        control_pin = "!PA1";
        pin_move_time = "0.675";
        stow_on_each_sample = false;
        probe_with_touch_mode = true;
        pin_up_touch_mode_reports_triggered  = true;
        pin_up_reports_not_triggered = false;
        speed = 3;
        lift_speed = 200;
        x_offset = -55;
        y_offset = -13;
        z_offset = 0;
        samples = 3;
        sample_retract_dist = 5.0;
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
        mesh_min = "10, 10";
        mesh_max = "195, 220";
        probe_count = "5,5";
        algorithm = "bicubic";
      };

      stepper_x = {
        step_pin = "PB13";
        dir_pin = "!PB12";
        enable_pin = "!PB14";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PC0";
        position_endstop = -17;
        position_min = -17;
        position_max = 235;
        homing_speed = 50;
      };

      "tmc2209 stepper_x" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 0;
        run_current = 0.580;
        hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      stepper_y = {
        step_pin = "PB10";
        dir_pin = "!PB2";
        enable_pin = "!PB11";
        microsteps = 16;
        rotation_distance = 40;
        endstop_pin = "^PC1";
        position_endstop = -5;
        position_min = -5;
        position_max = 235;
        homing_speed = 50;
      };

      "tmc2209 stepper_y" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 2;
        run_current = 0.580;
        hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      stepper_z = {
        step_pin = "PB0";
        dir_pin = "PC5";
        enable_pin = "!PB1";
        microsteps = 16;
        rotation_distance = 4;
        endstop_pin = "probe:z_virtual_endstop";
        position_max = 250;
        position_min = -5;
      };

      "tmc2209 stepper_z" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 1;
        run_current = 0.580;
        hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      extruder = {
        step_pin = "PB3";
        dir_pin = "!PB4";
        enable_pin = "!PD1";
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
        max_temp = 250;
      };

      "tmc2209 extruder" = {
        uart_pin = "PC11";
        tx_pin = "PC10";
        uart_address = 3;
        run_current = 0.650;
        hold_current = 0.500;
        stealthchop_threshold = 999999;
      };

      heater_bed = {
        heater_pin = "PC9";
        sensor_type = "ATC Semitec 104GT-2";
        sensor_pin = "PC4";
        control = "pid";
        pid_Kp = 54.027;
        pid_Ki = 0.770;
        pid_Kd = 948.182;
        min_temp = 0;
        max_temp = 130;
      };

      "heater_fan controller_fan" = {
        pin = "PB15";
        heater = "heater_bed";
        heater_temp = 45.0;
      };

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

      "gcode_macro CANCEL_PRINT" = {
        description = "Cancel the actual running print";
        rename_existing = "CANCEL_PRINT_BASE";
        gcode = "
        TURN_OFF_HEATERS
        CANCEL_PRINT_BASE
        ";
      };

      mcu = {
        serial = "/dev/serial/by-id/usb-Klipper_stm32g0b1xx_510014000250414235363020-if00";
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
        aliases = ''
          '
                    # EXP1 header
                    EXP1_1=PB5,  EXP1_3=PA9,   EXP1_5=PA10, EXP1_7=PB8, EXP1_9=<GND>,
                    EXP1_2=PA15, EXP1_4=<RST>, EXP1_6=PB9,  EXP1_8=PD6, EXP1_10=<5V>
        '';
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
