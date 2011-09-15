<cfoutput>
	<h3>Wordpress</h3>	
	<p>Upload your Wordpress XML File.</p>
	<form name="fileUpload" method="post" action="?mcAction=wordpress.import" enctype="multipart/form-data">
		<input type="file" name="wordpressXML" />
		<button type="submit">Upload</button>
	</form>
</cfoutput>