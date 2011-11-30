<cfoutput><plugin>
	<name>Mura Converter</name>
	<package>MuraConverter</package>
	<directoryFormat>packageOnly</directoryFormat>
	<loadPriority>5</loadPriority>
	<version>0.2</version>
	<provider>Greg Moser</provider>
	<providerURL>http://www.gregmoser.com</providerURL>
	<category>Application</category>
	<settings>
		<!---<setting>
			<name>Setting Name</name>
			<label>Setting Label</label>
			<hint>Setting Hint</hint>
			<type>RadioGroup</type>
			<required>false</required>
			<validation></validation>
			<regex></regex>
			<message>Setting message</message>
			<defaultvalue>1</defaultvalue>
			<optionlist>0^1</optionlist>
			<optionlabellist>No^Yes</optionlabellist>
		</setting>--->	
	</settings>
	<eventHandlers>
		<eventHandler event="onApplicationLoad" component="pluginEventHandler" persist="false" />
	</eventHandlers>
	<displayobjects location="global">
		<!---<displayobject name="muraFW1" displaymethod="renderApp" component="pluginEventHandler" persist="false" />--->
	</displayobjects>
</plugin></cfoutput>