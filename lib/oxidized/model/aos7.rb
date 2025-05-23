class AOS7 < Oxidized::Model
  using Refinements

  # Alcatel-Lucent Operating System Version 7 (Linux based)
  # used in OmniSwitch 6900/10k

  prompt /^([\w.@-]+ ?[#>]\s?)$/

  comment  '! '

  cmd :all do |cfg, cmdstring|
    new_cfg = comment "COMMAND: #{cmdstring}\n"
    new_cfg << cfg.cut_both
  end

  cmd 'show system' do |cfg|
    cfg = cfg.each_line.find { |line| line.match 'Description' }
    comment cfg.to_s.strip + "\n"
  end

  cmd 'show chassis' do |cfg|
    # check for virtual chassis existence
    @slave_vcids = cfg.scan(/Chassis ID (\d+) \(Slave\)/).flatten
    @master_vcid = Regexp.last_match(1) if cfg =~ /Chassis ID (\d+) \(Master\)/
    comment cfg
  end

  cmd 'show hardware-info' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n\n/, "\n\n"
    comment cfg
  end

  cmd 'show running-directory' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n/, "\n"
    comment cfg
  end

  cmd 'show configuration snapshot' do |cfg|
    # Remove extra lines occuring when the command runs slow
    cfg.gsub! /^Please wait...\n/, ''
    cfg.gsub! /^\n\n/, "\n"
    cfg
  end

  pre do
    cfg = []
    if @master_vcid
      # add slave VC boot config as comment
      @slave_vcids.each do |id|
        cfg << comment("vc_boot.cfg for slave chassis #{id}")
        cfg << comment(cmd("show configuration vcm-snapshot chassis-id #{id}"))
      end
      cfg << cmd("show configuration vcm-snapshot chassis-id #{@master_vcid}")
    end
    cfg.join "\n"
  end

  cfg :telnet do
    username /^([\w -])*login: /
    password /^Password\s?: /
  end

  cfg :telnet, :ssh do
    pre_logout 'exit'
  end
end
