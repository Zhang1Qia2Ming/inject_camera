# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "FRAME_LINES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "LINE_BEATS" -parent ${Page_0}


}

proc update_PARAM_VALUE.FRAME_LINES { PARAM_VALUE.FRAME_LINES } {
	# Procedure called to update FRAME_LINES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_LINES { PARAM_VALUE.FRAME_LINES } {
	# Procedure called to validate FRAME_LINES
	return true
}

proc update_PARAM_VALUE.LINE_BEATS { PARAM_VALUE.LINE_BEATS } {
	# Procedure called to update LINE_BEATS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LINE_BEATS { PARAM_VALUE.LINE_BEATS } {
	# Procedure called to validate LINE_BEATS
	return true
}


proc update_MODELPARAM_VALUE.LINE_BEATS { MODELPARAM_VALUE.LINE_BEATS PARAM_VALUE.LINE_BEATS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LINE_BEATS}] ${MODELPARAM_VALUE.LINE_BEATS}
}

proc update_MODELPARAM_VALUE.FRAME_LINES { MODELPARAM_VALUE.FRAME_LINES PARAM_VALUE.FRAME_LINES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_LINES}] ${MODELPARAM_VALUE.FRAME_LINES}
}

