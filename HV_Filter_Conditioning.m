// Under development
// Program to condition HV filters for the LEGEND experiment
// Author: Kevin Bhimani (kevin_bhimani@unc.edu)

function hv_condtion_step(channel, condition_voltage, init_voltage, volt_step, absolute_max_current){
    print("Conditioning Channel #", channel);
    hv = find(OREHS8260pModel,0,4);
    condition_v_perc = 5; // percent change we want for each conditoning step
    monitor_time = 5*60;
    discharge_current = 5;
    max_discharges = 1; // max number of discharges before we don't ramp up

    if(![hv isOn: channel]){
        initialize(channel, init_voltage, volt_step, absolute_max_current);
        sleep(ceil(init_voltage/volt_step) + 5);
        return 0;
    }

    voltage = [hv voltage: channel];
    error = 1; //wiggle room in getting to conditioning potential
    if((voltage < condition_voltage+error) && (voltage>condition_voltage-error)){
        return 1; 
    }

    //we go up potential and monitor the discharges
    new_potential = floor(voltage + voltage*condition_v_perc/100);
    print("Attempting to condition at ", new_potential, "V");
    [hv setTarget: channel withValue: new_potential];
    [hv loadValues: channel];
    sleep((ceil(voltage*condition_v_perc/100)/volt_step)+5);

    discharges = 0;
    [hv setMaxCurrent: channel withValue: discharge_current]; //we defines spikes above 5uA as discharges
    time_init = time();
    while(time()<time_init+monitor_time){
    if(new_potential - [hv voltage: channel] > volt_step){ //current trip will rampdown the HV supply
            print("Discharge recorded at channel: ", channel);
            [hv clearEventsChannel:channel];
            discharges+=1;
            if(![hv isOn: channel]){
                [hv turnChannelOn: channel];
            }
            [hv setTarget: channel withValue: new_potential];
            sleep((ceil(new_potential-[hv current: channel])/volt_step)+5);
        }
        sleep(1);
    }
    [hv setMaxCurrent: channel withValue: absolute_max_current* pow(10,6)]; //since the max current are set in micro_amps



    print("Number of discharges above ",discharge_current, " uA was ", discharges);

    if(discharges> max_discharges){
        print("Setting voltage to ", voltage);
        [hv setTarget: channel withValue: voltage];
        [hv loadValues: channel];
        sleep((ceil(voltage*condition_v_perc/100)/volt_step)+5);
        return 0;
    }

    print("Setting voltage to ", new_potential); //else we let it sit there
    return 0;
}

function initialize(channel, initial_voltage, volt_step, absolute_max_current){
    hv = find(OREHS8260pModel,0,4);
    [hv turnChannelOn: channel];
    [hv setVoltageStep: channel withValue: volt_step];
    [hv setTarget: channel withValue: initial_voltage];
    [hv setMaxCurrent: channel withValue: absolute_max_current* pow(10,6)]; //since the max current are set in micro_amps
    [hv setCurrentTripBehavior: channel withValue: 1];
    [hv loadValues: channel];
}

function shut_down(channel){
    hv = find(OREHS8260pModel,0,4);
    [hv setTarget: channel withValue: 0];
    [hv loadValues: channel];
}

function main(){
    hv = find(OREHS8260pModel,0,4);
    condition_voltage = 5000;
    absolute_max_current = 10 * pow(10, -6); //this will trip the HV supply
    init_voltage = 2000;
    volt_step = 20;

    initialize(0, init_voltage,volt_step, absolute_max_current);
    initialize(1, init_voltage, volt_step, absolute_max_current);
    initialize(2, init_voltage,volt_step, absolute_max_current);
    // initialize(3, init_voltage,volt_step, absolute_max_current);
    //initialize(7, init_voltage,volt_step, absolute_max_current);
    // initialize(5, init_voltage, volt_step, absolute_max_current);
    // initialize(7, init_voltage,volt_step, absolute_max_current);
    sleep(ceil(init_voltage/volt_step) + 30);
    print("Done initializing");
    is_condtioned = 0;
    while (!is_condtioned){
        is_condtioned = hv_condtion_step(0, condition_voltage, init_voltage, volt_step, absolute_max_current);
        is_condtioned = hv_condtion_step(1, condition_voltage, init_voltage, volt_step, absolute_max_current);
        is_condtioned = hv_condtion_step(2, condition_voltage, init_voltage, volt_step, absolute_max_current);
        is_condtioned = 0;
    }
    shut_down(4);
    }