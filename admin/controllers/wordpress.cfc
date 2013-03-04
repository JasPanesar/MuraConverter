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

        <!---   Strip any encoding character before the start of the xml file otherwise xmlParse can get a bit moody
                http://www.bennadel.com/blog/1206-Content-Is-Not-Allowed-In-Prolog-ColdFusion-XML-And-The-Byte-Order-Mark-BOM-.htm --->

        <cfset wpXML = xmlparse( REReplace( rawXML, "^[^<]*", "", "all" ) ) />

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
                            content.setRemoteID(item["wp:post_id"].xmlText); 
                            content.setReleaseDate(item["pubdate"].xmlText);
                            content.setURLTitle(item["wp:post_name"].xmlText);
                            content.setCredits(item["dc:creator"].xmlText);
                            content.setApproved(1);							
                            content.setSiteID(rc.$.event('siteID'));
                            content.setBody( cleanWPPost(  item["content:encoded"].xmlText , rc ) );

                            // Set the post status in WP to decide whether to make the post visible in Wordpress or not.
                            if(item["wp:status"].xmlText IS "publish") {
                                    content.setIsNav(1);
                                    content.setDisplay(1); 
                                } else if(item["wp:status"].xmlText IS "draft") { 
                                    //don't display or be in the nav
                                    content.setIsNav(0);
                                    content.setDisplay(0);
                                } else {
                                    content.setIsNav(0);
                                    content.setDisplay(0);
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
                                    
                                    // TODO: Add something here to filter out the spam comments -- don't want to import those.


                                    // We look to load the comment first before adding it.  We try to find one where the contentID & the date entered match.
                                    var comment = rc.$.getBean("comment").loadBy(entered="#item["wp:comment"][i]["wp:comment_date"].xmlText#", contentID=content.getContentID());

                                    // If the comment we loaded doesn't have anything in the actual comment, but the wp comment does, then we update it.  This is only used because getIsNew() doesn't work for comments
                                    if(!len(comment.getComments()) && len(item["wp:comment"][i]["wp:comment_content"].xmlText)) {

                                        // Set the simple values of the comment
                                        comment.setContentID    (content.getContentID());
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

                <cfset rc.wpitem = wpXML.rss.channel />
                <cfset rc.content = content />

			</cfloop>
        </cfloop>

        <cfset rc.siteConfig = rc.$.siteConfig()/>
        <cfset rc.expandpath = expandpath( "./" ) />
		
    </cffunction>





    <!--- functions for this cfc that really should be sitting somewhere else. --->

    <cfscript>


    // function to reverse HTMLEditFormat  -- not using at the moment but it's here for inspiration for cleanWPPost()
    function HtmlUnEditFormat( str )
    {
        var lEntities       = "&##xE7;,&##xF4;,&##xE2;,&Icirc;,&Ccedil;,&Egrave;,&Oacute;,&Ecirc;,&OElig,&Acirc;,&laquo;,&raquo;,&Agrave;,&Eacute;,&le;,&yacu    te;,&chi;,&sum;,&prime;,&yuml;,&sim;,&beta;,&lceil;,&ntilde;,&szlig;,&bdquo;,&acute;,&middot;,&ndash;,&sigmaf;,&reg;,&dagger;,&oplus;,&otilde;,&eta;,&rceil;,&oacute;,&shy;,&gt;,&phi;,&ang;,&rlm;,&alpha;,&cap;,&darr;,&upsilon;,&image;,&sup3;,&rho;,&eacute;,&sup1;,&lt;,&cent;,&cedil;,&pi;,&sup;,&divide;,&fnof;,&iquest;,&ecirc;,&ensp;,&empty;,&forall;,&emsp;,&gamma;,&iexcl;,&oslash;,&not;,&agrave;,&eth;,&alefsym;,&ordm;,&psi;,&otimes;,&delta;,&ouml;,&deg;,&cong;,&ordf;,&lsaquo;,&clubs;,&acirc;,&ograve;,&iuml;,&diams;,&aelig;,&and;,&loz;,&egrave;,&frac34;,&amp;,&nsub;,&nu;,&ldquo;,&isin;,&ccedil;,&circ;,&copy;,&aacute;,&sect;,&mdash;,&euml;,&kappa;,&notin;,&lfloor;,&ge;,&igrave;,&harr;,&lowast;,&ocirc;,&infin;,&brvbar;,&int;,&macr;,&frac12;,&curren;,&asymp;,&lambda;,&frasl;,&lsquo;,&hellip;,&oelig;,&pound;,&hearts;,&minus;,&atilde;,&epsilon;,&nabla;,&exist;,&auml;,&mu;,&frac14;,&nbsp;,&equiv;,&bull;,&larr;,&laquo;,&oline;,&or;,&euro;,&micro;,&ne;,&cup;,&aring;,&iota;,&iacute;,&perp;,&para;,&rarr;,&raquo;,&ucirc;,&omicron;,&sbquo;,&thetasym;,&ni;,&part;,&rdquo;,&weierp;,&permil;,&sup2;,&sigma;,&sdot;,&scaron;,&yen;,&xi;,&plusmn;,&real;,&thorn;,&rang;,&ugrave;,&radic;,&zwj;,&there4;,&uarr;,&times;,&thinsp;,&theta;,&rfloor;,&sub;,&supe;,&uuml;,&rsquo;,&zeta;,&trade;,&icirc;,&piv;,&zwnj;,&lang;,&tilde;,&uacute;,&uml;,&prop;,&upsih;,&omega;,&crarr;,&tau;,&sube;,&rsaquo;,&prod;,&quot;,&lrm;,&spades;" ;
        var lEntitiesChars  = "ç,ô,â,Î,Ç,È,Ó,Ê,Œ,Â,«,»,À,É,?,ý,?,?,?,Ÿ,?,?,?,ñ,ß,„,´,·,–,?,®,‡,?,õ,?,?,ó,­,>,?,?,?,?,?,?,?,?,³,?,é,¹,<,¢,¸,?,?,÷,ƒ,¿,ê,?,?,?,?,?,¡,ø,¬,à,ð,?,º,?,?,?,ö,°,?,ª,‹,?,â,ò,ï,?,æ,?,?,è,¾,&,?,?,“,?,ç,ˆ,©,á,§,—,ë,?,?,?,?,ì,?,?,ô,?,¦,?,¯,½,¤,?,?,?,‘,…,œ,£,?,?,ã,?,?,?,ä,?,¼, ,?,•,?,«,?,?,€,µ,?,?,å,?,í,?,¶,?,»,û,?,‚,?,?,?,”,?,‰,²,?,?,š,¥,?,±,?,þ,?,ù,?,?,?,?,×,?,?,?,?,?,ü,’,?,™,î,?,?,?,˜,ú,¨,?,?,?,?,?,?,›,?,"",?,?";
        return ReplaceList( arguments.str , lEntities , lEntitiesChars );
    }



    function cleanWPPost ( str , rc ) {
        /**
            Cleans up Linux generated WordPress XML files that have encoding issues when it comes to linebreaks, etc that show up as extended ascii characters in the XML.
            Since the majority of Wordpress installations are linux based, this type of scenario may come up pretty regularly. 
            This isn't the cleanest or prettiest way to do this, until all the error cases are found we can collect them here and then hit them together.
            * 
        * @param inString      String to format. (Required) 
        * @return Returns a string. 
         */


        arguments.str = ReReplace( arguments.str , "\r"         , ""        , "ALL" );      // Remove any \r characters (represented as $ in vim) Seems to be needed
        arguments.str = ReReplace( arguments.str , "\n"         , "<br/>"   , "ALL" );      // This finds all embedded line breaks inside the file and inserts proper breaks. (represented as ^M in vim).  Seems to be needed

        arguments.str = ReReplace( arguments.str , "&dagger;"   , ""        , "ALL" );      // remove all &dagger; references that seem to consistently appear from a unix wordpress xml export.
        arguments.str = ReReplace( arguments.str , "†"          , ""        , "ALL" );      // remove all &dagger; references that seem to consistently appear from a unix wordpress xml export.

        arguments.str = ReReplace( arguments.str , "¬"          , ""        , "ALL" );      // remove all &not; references that seem to consistently appear from a unix wordpress xml export.
        arguments.str = ReReplace( arguments.str , "&not;"      , ""        , "ALL" );      // remove all &not; references that seem to consistently appear from a unix wordpress xml export.


        arguments.str = importImages(arguments.str, rc);

        return str;
    }


    function xmlFormat2( inString ) {

    /**
     * Similar to xmlFormat() but replaces all characters not on the &quot;good&quot; list as opposed to characters specifically on the &quot;bad&quot; list.
     * 
    * @param inString      String to format. (Required) 
    * @return Returns a string. 
    * @author Samuel Neff (sam@serndesign.com) 
    * @version 1, January 12, 2004 
     */

       var goodChars = "!@##$%^*()0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`~[]{} ;:,./?\| -_=+#chr(13)##chr(10)##chr(9)#" ;
       var i = 1;
       var c = "";     
       var s = "";
       
       for (i=1; i LTE len(inString); i=i+1) {
          
          c = mid(inString, i, 1);
          
          if (find(c, goodChars)) {
             s = s & c;
          } else {
             s = s & "&##" & asc(c) & ";";
          }
       }
       
       return s;
    }
    </cfscript>

    <cffunction name="importImages" output="false" returntype="any">
        <!---   This fuction searches provided html snippet for img tags, download the embedded images (assuming they have absolute paths)
                and then uploads them to the mura assets/images folder.  Ideally this shoudl do it through the Mura backend itself,
                but, it's a bearable start that's better than nothing. --->

        <cfargument name = "str" />
        <cfargument name = "rc" />

        <!--- let's scan the html for any <img> tags using jsoup --->
        <cfscript>

            //use Mura's Javaloader to load Jsoup.
            paths       = arrayNew( 1 );
            paths[1]    = expandPath( "jsoup-1.7.2.jar" );

            loader      = createObject( "component" , "mura.javaloader.JavaLoader" ).init( paths );
            jsoup       = loader.create( "org.jsoup.Jsoup" );

            //parse the provided content and select all image tags
            doc         = jsoup.parse( arguments.str );
            imagelinks  = doc.select( "img" ); 
        </cfscript>

        <!---   let's loop through the images jsoup finds, download them to the Mura Site asset folder and then update the link in the html
                to point to the Mura {siteid}/assets/Image/ folder.--->
        <cfloop index = "image" array = "#imagelinks#" >
            <cfoutput>
            <!--- set the disk paths for the file path and name we'll have to write out locally --->
            <cfset local.writePath      = "#expandpath( "./../../" )##rc.$.siteConfig( 'siteid' )#/assets/Image/"     />
            <cfset local.imageFileName  = listFirst( listLast(#image.attr('src')# , "/\") , "?" )                         /> 
            
            <!--- download the image and then set it as the attribute --->
            <cfimage action = "write" source = "#image.attr( 'src' )#" destination="#local.writepath##local.imageFileName#" overwrite="true"  />
            <cfset #image.attr( 'src' , '#rc.$.siteConfig( 'assetPath' )#/Assets/Image/#local.imageFileName#' )#                                 />
            </cfoutput>
        </cfloop>

        <cfreturn doc />

    </cffunction>


</cfcomponent>
