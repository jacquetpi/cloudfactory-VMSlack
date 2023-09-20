import yaml, math, random

class PremiumBuilder(object):
    """
    A class used to attribute a premium level to VM list
    ...

    Public Methods
    -------
    attribute_usage_to_vm_list(vmlist : list):
       Update a list of VM with randomly selected premium level
    generate_set_from_config(number_of_vm : int):
        Generate a list of scenario compliant VM based on node cpu and memory available
    """

    def __init__(self, **kwargs):
        required_attributes = ["yaml_file"]
        for required_attribute in required_attributes:
            if required_attribute not in kwargs: raise ValueError("Missing required attributes", required_attribute, "in", required_attributes)
        self.__load_from_yaml(kwargs["yaml_file"])

    def __load_from_yaml(self, yaml_file : str):
        """Initiate attributes from yaml config file

        Parameters
        ----------
        yaml_file : str
            Yaml file location

        Raises
        ------
        ValueError
            If sum of frequencies are not equals to 1
        """
        with open(yaml_file, 'r') as file:
            yaml_as_dict = yaml.full_load(file)
            
        self.premium_levels = yaml_as_dict["vm_premium"]

        if round(sum(self.premium_levels.values()),2) > 1.0:
           print("Warning : Premium levels distribution frequency exceeded 1")
           self.premium_levels = self.__reduce_freq_to_one(self.premium_levels)

    def attribute_premium_level_to_vm_list(self, vm_list : list):
        """ Attribute a premium level to each vm in a list
        ----------
        vm_list : list
            list of VMs to be updated
        """
        premium_list = self.__generate_premium_list(number_of_level=len(vm_list))
        for count, vm in enumerate(vm_list):
            vm.set_premium_level(premium_list[count])

    def __generate_premium_list(self, number_of_level : int):
        """ Generate a list of premium levels. List is shuffled to avoid even distribution on a same set of VM
        Parameters
        ----------
        number_of_level : int
            Number of level to be generated

        Returns
        -------
        premium_list : list
            list of premium levels
        """
        premium_list = list()
        for premium_tag, premium_freq in self.premium_levels.items():
            count_for_specific_tag = math.ceil(number_of_level*premium_freq)
            premium_list.extend([premium_tag for x in range(count_for_specific_tag)])

        delta = number_of_level - len(premium_list)
        while delta>0: # manage rounded values
            for profile_id in self.profiles.keys():
                if delta <=0: break
                premium_list.append(profile_id)
                delta-=1

        random.shuffle(premium_list)
        return premium_list

    def __reduce_freq_to_one(self, dict_to_reduce):
        """ Reduce a dict of frequencies so its values are equals to one
        Parameters
        ----------
        dict_to_reduce : dict
            Dict of frequencies (key : config, value : freq)
        """
        print("Distribution was reduced as described:")
        original = dict(dict_to_reduce)
        delta = round(sum(dict_to_reduce.values()) - 1, 2)
        keys = list(dict_to_reduce.keys())
        keys.sort(reverse=True)
        while delta>0:
            key = keys.pop(0)
            if delta > original[key]:
                delta-= original[key]
                dict_to_reduce[key] = 0
            else:
                dict_to_reduce[key] = dict_to_reduce[key] - delta
                delta=0
        for key in dict_to_reduce.keys():
            print(key, ":", original[key], "->", dict_to_reduce[key])
        return dict_to_reduce