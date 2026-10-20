# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "last_total" -parent ${Page_0}


}

proc update_PARAM_VALUE.last_total { PARAM_VALUE.last_total } {
	# Procedure called to update last_total when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.last_total { PARAM_VALUE.last_total } {
	# Procedure called to validate last_total
	return true
}


proc update_MODELPARAM_VALUE.last_total { MODELPARAM_VALUE.last_total PARAM_VALUE.last_total } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.last_total}] ${MODELPARAM_VALUE.last_total}
}

