<cfoutput>
    <h2>Wordpress Import</h4>	

    <h3>Step 1: Create upload location in Mura if needed</h3>
    <blockquote>
        <p>If you haven't created a Blog or Other type of Folder/Portal in the <a href="http://localhost/damaag/admin/index.cfm?muraAction=cArch.list&siteid=#rc.siteid#&moduleid=00000000000000000000000000000000000">Site Manager</a>, go do that first and then return here.</p>
    </blockquote>

    <h3>Step 2: Select location in Mura to import under:</h3>
    <blockquote> 
    <p>Blog posts from Wordpress will be uploaded under this Mura location.  Selecting a Mura Folder/Portal is reccomended.</p>


    <form name="fileUpload" method="post" action="?mcAction=wordpress.import" enctype="multipart/form-data">
    <p><br/>
    Import under this Mura location:
    <select name="contentID">
      <option value="00000000000000000000000000000000001">Home</option>
      <cfloop query = "rc.kidsIterator">
          <option value = "#rc.kidsIterator.contentid#">#rc.kidsIterator.title# (#rc.kidsIterator.type#)</option>
      </cfloop>
      </select>
    </blockquote>

    <h3>Step 3: Select your Wordpress XML file to upload</h3>
    <blockquote>
		<input type="file" name="wordpressXML" />
        <button type="submit">Upload + Import!</button>
    
    <p>You can export your Wordpress XML file from your WP Admin under Tools > Export</p>
    
    </form>
    </blockquote>

    <!--- debug <cfdump var="#rc#">--->

</cfoutput>
