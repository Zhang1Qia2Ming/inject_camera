# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BYTENUM" -parent ${Page_0}
  ipgui::add_param $IPINST -name "H_Active" -parent ${Page_0}
  ipgui::add_param $IPINST -name "H_Total" -parent ${Page_0}
  ipgui::add_param $IPINST -name "V_Active" -parent ${Page_0}
  ipgui::add_param $IPINST -name "V_Total" -parent ${Page_0}


}

proc update_PARAM_VALUE.BYTENUM { PARAM_VALUE.BYTENUM } {
	# Procedure called to update BYTENUM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BYTENUM { PARAM_VALUE.BYTENUM } {
	# Procedure called to validate BYTENUM
	return true
}

proc update_PARAM_VALUE.H_Active { PARAM_VALUE.H_Active } {
	# Procedure called to update H_Active when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.H_Active { PARAM_VALUE.H_Active } {
	# Procedure called to validate H_Active
	return true
}

proc update_PARAM_VALUE.H_Total { PARAM_VALUE.H_Total } {
	# Procedure called to update H_Total when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.H_Total { PARAM_VALUE.H_Total } {
	# Procedure called to validate H_Total
	return true
}

proc update_PARAM_VALUE.V_Active { PARAM_VALUE.V_Active } {
	# Procedure called to update V_Active when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.V_Active { PARAM_VALUE.V_Active } {
	# Procedure called to validate V_Active
	return true
}

proc update_PARAM_VALUE.V_Total { PARAM_VALUE.V_Total } {
	# Procedure called to update V_Total when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.V_Total { PARAM_VALUE.V_Total } {
	# Procedure called to validate V_Total
	return true
}


proc update_MODELPARAM_VALUE.H_Total { MODELPARAM_VALUE.H_Total PARAM_VALUE.H_Total } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.H_Total}] ${MODELPARAM_VALUE.H_Total}
}

proc update_MODELPARAM_VALUE.H_Active { MODELPARAM_VALUE.H_Active PARAM_VALUE.H_Active } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.H_Active}] ${MODELPARAM_VALUE.H_Active}
}

proc update_MODELPARAM_VALUE.V_Total { MODELPARAM_VALUE.V_Total PARAM_VALUE.V_Total } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.V_Total}] ${MODELPARAM_VALUE.V_Total}
}

proc update_MODELPARAM_VALUE.V_Active { MODELPARAM_VALUE.V_Active PARAM_VALUE.V_Active } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.V_Active}] ${MODELPARAM_VALUE.V_Active}
}

proc update_MODELPARAM_VALUE.BYTENUM { MODELPARAM_VALUE.BYTENUM PARAM_VALUE.BYTENUM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BYTENUM}] ${MODELPARAM_VALUE.BYTENUM}
}

