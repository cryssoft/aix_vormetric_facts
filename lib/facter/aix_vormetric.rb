Facter.add(:aix_vormetric) do
    #  This only applies to the AIX operating system
    confine :osfamily => 'AIX'

    #  Capture the installation status and version if it's there
    setcode do

        l_aixVormetric={}
        l_aixVormetric['guarded']={}
        l_aixVormetric['installed']=false
        l_aixVormetric['version']='(unknown)'
        l_aixVormetric['vmd_url']='(unknown)'

        #  Look for a file to see if the product is installed at all
        if (File.exists? '/opt/vormetric/DataSecurityExpert/agent/secfs/.sec/bin/secfsd')
            #  If so, mark it in the hash
            l_aixVormetric['installed']=true

            #  Then, look for guarded directories / mount points
            l_lines = Facter::Util::Resolution.exec('/bin/secfsd -status guard 2>/dev/null')
            l_lines && l_lines.split("\n").each do |l_oneLine|
                #  Skip the headings
                l_oneLine = l_oneLine.strip()
                next if l_oneLine =~ /^Guard/ or l_oneLine =~ /^-/ or l_oneLine =~ /^No/
                #  Each one should be unique, so add it to the hash, and fill it as the next level
                l_list=l_oneLine.split()
                if l_list.length == 6
                    l_aixVormetric['guarded'][l_list[0]]={}
                    l_aixVormetric['guarded'][l_list[0]]['policy']=l_list[1]
                    l_aixVormetric['guarded'][l_list[0]]['type']=l_list[2]
                    l_aixVormetric['guarded'][l_list[0]]['config']=l_list[3]
                    l_aixVormetric['guarded'][l_list[0]]['status']=l_list[4]
                    l_aixVormetric['guarded'][l_list[0]]['reason']=l_list[5]
                else
                    l_aixVormetric['guarded'][l_list[0]]={}
                    l_aixVormetric['guarded'][l_list[0]]['policy']=l_list[1]
                    l_aixVormetric['guarded'][l_list[0]]['type']=l_list[2]
                    l_aixVormetric['guarded'][l_list[0]]['config']=l_list[3]
                    l_aixVormetric['guarded'][l_list[0]]['status']=l_list.slice(4..5).join(' ')
                    l_aixVormetric['guarded'][l_list[0]]['reason']=l_list.slice(6..-1).join(' ')
                end
            end

            #  Then, grab the version information
            l_lines = Facter::Util::Resolution.exec('/bin/vmd -v 2>/dev/null')
            l_lines && l_lines.split("\n").each do |l_oneLine|
                #  Skip the headings
                l_oneLine = l_oneLine.strip()
                if l_oneLine =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/
                    l_aixVormetric['version']=l_oneLine
                end
            end

            #  Then, grab the vmd_PRIMARY_URL
            l_lines = Facter::Util::Resolution.exec('/bin/vmsec status 2>/dev/null')
            l_lines && l_lines.split("\n").each do |l_oneLine|
                #  Skip the headings
                l_oneLine = l_oneLine.strip()
                l_items   = l_oneLine.split('=')
                if l_items[0] == 'vmd_PRIMARY_URL'
                    l_aixVormetric['vmd_url']=l_items[1]
                end
            end
        end

        #  Implicitly return the contents of the hash
        l_aixVormetric
    end
end
