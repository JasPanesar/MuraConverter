<cfoutput>
    <h2>Wordpress Import</h4>
    <blockquote>
    <p>Before you begin, please be aware that exporting the XML file of your posts from Wordpress might result in a truncated/incomplete file if the WP export script request times out.  The chances of this goes up if you have a lot of posts, or a ton of spam comments on your posts which increase the size of the file over a few megs. The broken xml file that WP outputs, as a result will not be able to be imported into Mura, and this Mura Convertor will give you messages like the XML structure is missing something, etc.  Opening the XML file will reveal that you are indeed missing things like the /xml and /channel from the end of the XML file.<br/><br/>
    To ensure you get a complete XML file out of Wordpress you may have to insert set_time_limit(1000); at the top of the export_wp() function in /wp-admin/includes/export.php.  If this does not work you may also have to increase your Apache webserver timeout using the Timeout Directive, to Timeout 1000 in your vhost config or apache config.  </P>
    </blockquote>

    <h3>Step 1: Create upload location in Mura site manager if needed</h3>
    <blockquote>
    <p>Select the site you'd like to upload into.<br/>
    Current SiteID is: [#rc.siteid#]. <br/><br/>
    If you haven't created a Blog or Other type of Folder/Portal in the <a href="http://localhost/damaag/admin/index.cfm?muraAction=cArch.list&siteid=#rc.siteid#&moduleid=00000000000000000000000000000000000">Site Manager</a>, go do that first and then return here.</p>
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

    <h3>Step 3: Import Options</h3>
    <blockquote>
    <p>
    Import Wordpress blog categories: <input type = "checkbox" name = "importCategories" value = "true" checked /><br/>
        Note: Categories may not import in older versions of Wordpress
    <!--- this isn't quite working yet, just merged from devel for the time being
    <br/><br/>
    Import Wordpress blog comments: <input type = "checkbox" name = "importComments" value = "true" checked />--->
    </p>
    </blockquote>

    <h3>Select your Wordpress XML file to upload</h3>
    <blockquote>
		<input type="file" name="wordpressXML" />
        <button type="submit">Upload + Import!</button>
    
    <p>You can export your Wordpress XML file from your WP Admin under Tools > Export</p>
    
    </form>
    </blockquote>

    <!--- debug <cfdump var="#rc#">--->

</cfoutput>
