  CONSTANT num_of_taps=D’31’
  CONSTANT dist_to_last_tap=num_of_taps-1
  CONSTANT dist_to_prv_to_last_tap=num_of_taps-2
 ;define filter coeffs here
	CONSTANT coeff0=0xce ;corresponds to the latest sample
	CONSTANT coeff1=0x0d
	CONSTANT coeff2=0x59
	CONSTANT coeff3=0x0d
	CONSTANT coeff4=0xcf
