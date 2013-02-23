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

        <!--- inputs from form on what to import --->
        <cfparam name = "form.contentID"        default = "00000000000000000000000000000000001" />  
        <cfparam name = "form.importCategories" default = "false" />
        <cfparam name = "form.importComments"   default = "false" />



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

                        /* If this content-node has a parent that is 0 then use the parentContentID that was passed in, otherwise try to figure out where it was nested */
						if(item["wp:post_parent"].xmlText eq 0) {
                            /*parentContent = rc.$.getBean("content").loadBy(contentID="00000000000000000000000000000000001");*/
                            parentContent = rc.$.getBean("content").loadBy(contentID=form.contentID);
						} else {
							parentContent = rc.$.getBean("content").loadBy(remoteID=item["wp:post_parent"].xmlText);
						}

                        // If the parentContent doesn't exist yet in Mura, then we will have to come back to this node on the next pass
						if(parentContent.getIsNew()) {
                            allParentsFound = false;

                        // If the parentContent was found, then we can add this content node to mura.
                        } else {
                            // Try to load the content first, in case this is a second upload of the same data
                            content = rc.$.getBean("content").loadBy(remoteID=item["wp:post_id"].xmlText);

                            // Set all the simple values of the content
							content.setParentID(parentContent.getContentID());
							content.setTitle(item["title"].xmlText);
							content.setBody(item["content:encoded"].xmlText);
                            content.setRemoteID(item["wp:post_id"].xmlText); 
                            content.setReleaseDate(item["pubdate"].xmlText);
                            content.setURLTitle(item["wp:post_name"].xmlText);
                            content.setCredits(item["dc:creator"].xmlText);
                            content.setApproved(1);							
                            content.setSiteID(rc.$.event('siteID'));

                                            
                            // Set the post status in WP to decide whether to make the post visible in Wordpress or not.
                            if(item["wp:status"].xmlText IS "publish") {
                                    content.setIsNav = 1;
                                    content.setDisplay = 1; 
                                } else { 
                                    //set everythign else to not display or be in the nav
                                    content.setIsNav = 0;
                                    content.setDisplay = 0;
                                }

                       
							// This will be used to set up categories if needed
							categoryList = "";


                            
                            // Conditionally attempt importing categories if it is selected.  This may not work in older versions of WP.
                            if(form.importCategories is "true") {
                                // Loop over the categories from WP to build out the categoryList to set in the content
                                for(var i=1; i<=arrayLen(item.category); i++) {
                                    var category = rc.$.getBean("category").loadBy(name="#item.category[i].xmlText#");
                                    if(category.getIsNew()) {
                                        category.setName(item.category[i].xmlText);
                                        
                                        category.save();	
                                    }
                                    categoryList = listAppend(categoryList, category.getCategoryID());
                                }
                                // Set the category list into the content        
                                content.setCategories(categoryList);
                           }

                            /*// conditionally attempt importing comments if it is selected.  This is merged in from the devel branch and may not work fully.
                            if(form.importComments is "true") {

                                // Loop over the comments that were assigned to this wp node
                                for(var i=1; i<=arrayLen(item["wp:comment"]); i++) {

                                    // We look to load the comment first before adding it.  We try to find one where the contentID & the date entered match.
                                    var comment = rc.$.getBean("comment").loadBy(entered="#item["wp:comment"][i]["wp:comment_date"].xmlText#", contentID=content.getContentID());

                                    // If the comment we loaded doesn't have anything in the actual comment, but the wp comment does, then we update it.  This is only used because getIsNew() doesn't work for comments
                                    if(!len(comment.getComments()) && len(item["wp:comment"][i]["wp:comment_content"].xmlText)) {

                                        // Set the simple values of the comment
                                        comment.setContentID(content.getContentID());
                                        comment.setIsApproved(1);
                                        comment.setSiteID(rc.$.event('siteID'));
                                        comment.setName(item["wp:comment"][i]["wp:comment_author"].xmlText);
                                        comment.setComments(item["wp:comment"][i]["wp:comment_content"].xmlText);
                                        comment.setEntered(item["wp:comment"][i]["wp:comment_date"].xmlText);
                                        // Only set the URL if the length is lest that 50.
                                        if(len(item["wp:comment"][i]["wp:comment_author_url"].xmlText) < 50) {
                                            comment.setUrl(item["wp:comment"][i]["wp:comment_author_url"].xmlText);
                                        }

                            }


                            // Not sure if this is needed anymore..? Merged in from devel. Setting the remoteAddr request scope variable that the comment bean requires to save to the DB.  We are setting it as the IP that came from WP. (This is all a workaround because of this issue: https://github.com/blueriver/MuraCMS/issues/222) 
                            request.remoteAddr = item["wp:comment"][i]["wp:comment_author_IP"].xmlText;*/

                            // save the content bean and move to the next item if there is one.
							content.save();	
						}
					}
				</cfscript>
			</cfloop>
		</cfloop>
		
	</cffunction>

</cfcomponent>
