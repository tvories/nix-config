_: {
  nix.gc = {
    automatic = true;

    interval = {
      Weekday = 0;
      Hour = 2;
      Minute = 0;
    };
  };

}
