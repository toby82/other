import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint

def get_pillar(__opts__, minion='*', **kwargs):
    saltenv = 'base'
    id_, grains, _ = salt.utils.minions.get_minion_data(minion, __opts__)
    if grains is None:
        grains = {'fqdn': minion}

    for key in kwargs:
        if key == 'saltenv':
            saltenv = kwargs[key]
        else:
            grains[key] = kwargs[key]

    pillar = salt.pillar.Pillar(
        __opts__,
        grains,
        id_,
        saltenv)

    compiled_pillar = pillar.compile_pillar()
    return compiled_pillar 

#def show():
#    client = salt.client.LocalClient(__opts__['conf_file'])
#    runner = salt.runner.RunnerClient(__opts__)
#    #pillar = runner.cmd('pillar.show_pillar', [])
#    #print pillar
#    return get_pillar()
     

