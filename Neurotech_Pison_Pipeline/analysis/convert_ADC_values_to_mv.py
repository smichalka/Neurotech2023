#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from typing import List, Tuple, Union

def convert_ADC_values_to_mv(values: List[Union[float, int]], voltage: float = 9.0, resolution: int = 24, gain: float = 50.4) -> List[float]:
    """
    Convert a list of raw values to millivolts (mV) using the provided parameters.

    Parameters:
        values (List[Union[float, int]]): The list of raw values to be converted.
        voltage (float): The voltage used in the conversion formula. Default is 9.0.
        resolution (int): The resolution used in the conversion formula. Default is 24.
        gain (float): The gain used in the conversion formula. Default is 50.4.

    Returns:
        List[float]: The list of converted values in millivolts (mV).
    """
    try:
        assert all(isinstance(y, (float, int)) for y in values), "Input 'values' must be a list of floats or integers."
        assert isinstance(voltage, float), "Parameter 'voltage' must be a float."
        assert isinstance(resolution, int), "Parameter 'resolution' must be an integer."
        assert isinstance(gain, float), "Parameter 'gain' must be a float."

        converted_values = [(y * (voltage / (2 ** resolution)) / gain) * 1000 for y in values]
        return converted_values
    except AssertionError as e:
        raise
    except Exception as e:
        raise