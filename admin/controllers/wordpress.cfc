<cfcomponent extends="controller" output="false">

	<cffunction name="default" output="false" returntype="any">
		<cfargument name="rc" />
		<!---<cfparam name="rc.save" default="false" />
        <cfparam name="rc.delete" default="false" />--->

		<cfscript>
            rc.siteid = rc.$.event('siteID');
            rc.KidsIterator = rc.$.getBean("content").loadBy(contentID="00000000000000000000000000000000001").getKidsQuery();
            rc.parentContent = rc.$.getBean("content").loadBy(contentID="00000000000000000000000000000000001");
		</cfscript>
	</cffunction>

	<cffunction name="import" output="false" returntype="any">
		<cfargument name="rc" />

		<cfset var newFilename = createUUID() & ".xml" />
		<cfset var importDirectory = expandPath(rc.$.siteConfig('assetPath')) & '/assets/file/muraConverter/wordpressImport/' />
		<cfset var rawXML = "" />
		<cfset var wpXML = "" />
		<cfset var item = "" />
		<cfset var parentContent = "" />
		<cfset var content = "" />
		<cfset var allParentsFound = false />
		<cfset var categoryList = "" />

        <cfparam name = "form.contentID" default = "00000000000000000000000000000000001" />   <!--- used on form post --->

		<cfif not directoryExists(importDirectory)>
			<cfset directoryCreate(importDirectory) />
		</cfif>
		
		<cffile action="upload" filefield="wordpressXML" destination="#importDirectory#" nameConflict="makeunique" result="uploadedFile">
		<cffile action="rename" destination="#importDirectory##newFilename#" source="#importDirectory##uploadedFile.serverFile#" >
		
		<cffile action="read" file="#importDirectory##newFilename#" variable="rawXML" >
		
		<cfset wpXML = xmlParse(rawXML) />
		
		<cfloop condition="allParentsFound eq false">
			<cfset allParentsFound = true />
			<cfloop array="#wpXML.rss.channel.item#" index="item">
				<cfscript>
					if(item["wp:post_type"].xmlText == "post" && len(item["title"].xmlText)) {
						if(item["wp:post_parent"].xmlText eq 0) {
                            /*parentContent = rc.$.getBean("content").loadBy(contentID="00000000000000000000000000000000001");*/
                            parentContent = rc.$.getBean("content").loadBy(contentID=form.contentID);
						} else {
							parentContent = rc.$.getBean("content").loadBy(remoteID=item["wp:post_parent"].xmlText);
						}
						
						if(parentContent.getIsNew()) {
							allParentsFound = false;
						} else {
							content = rc.$.getBean("content").loadBy(remoteID=item["wp:post_id"].xmlText);
							content.setParentID(parentContent.getContentID());
							content.setTitle(item["title"].xmlText);
							content.setBody(item["content:encoded"].xmlText);
                            content.setRemoteID(item["wp:post_id"].xmlText);  

                            if(item["wp:status"].xmlText IS "publish") {
                                content.setIsNav = 1;
                                content.setDisplay = 1; 
                                } else { 
                                //set everythign else to not display or be in the nav
                                content.setIsNav = 0;
                                content.setDisplay = 0;
                                }

                            content.setReleaseDate(item["pubdate"].xmlText);
                            content.setURLTitle(item["wp:post_name"].xmlText);
                            content.setCredits(item["dc:creator"].xmlText);


                            /*  add wp:post_date -- not quite woring yet
                            content.setReleaseDate("{ts '" & item["wp.post_date"].xmlText & "'}");
                            */


                            content.setApproved(1);							
                            content.setSiteID(rc.$.event('siteID'));
                            
							
							categoryList = "";
							
                            /* categories are not working for my import -- my WP might be too old.  Feel free to uncomment if you're using something recent
                            for(var i=1; i<=arrayLen(item.category); i++) {
								var category = rc.$.getBean("category").loadBy(name="#item.category[i].xmlText#");
								if(category.getIsNew()) {
									category.setName(item.category[i].xmlText);
									
									category.save();	
								}
								categoryList = listAppend(categoryList, category.getCategoryID());
							}
							
							content.setCategories(categoryList);*/
							
							content.save();	
						}
					}
				</cfscript>
			</cfloop>
		</cfloop>
		
	</cffunction>

</cfcomponent>
