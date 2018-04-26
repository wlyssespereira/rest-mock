# !/bin/bash
# @Author Wlysses S. Pereira
# 

if [ ! -e templates ]; then
	mkdir templates
fi

if [ ! -e templates/header ]; then
	echo 'HTTP/1.1 200 OK' >> templates/header;
	echo 'Location:' >> templates/header;
	echo 'Content-Type: application/json' >> templates/header;
	echo -e "\n\n" >> templates/header;
fi

if [ ! -e templates/json ]; then
	echo -e '\n\r{"name":"Rest Mock", "version":"0.1", "author":"Wlysses Pereira", "license":""}' > templates/json
fi

# Checks whether the services folder exists and displays the available services.
if [ ! -e "services" ]; then
	echo "No avaliable services."
    mkdir services;
else
	echo "Available static services:"
    ls services | xargs;
fi

rm -f .out
mkfifo .out
trap "rm -f .out" EXIT
while true
do
	cat .out | nc -l 1500 > >(
		export REQUEST=
		echo -e "\n##################################################"
		while read -r line
		do
			echo $line;
			line=$(echo "$line" | tr -d '[\r\n]')
			if echo "$line" | grep -qE '^(GET|PUT|POST|DELETE) /'
			then
				TYPE=$(echo "$line" | cut -d ' ' -f1)
				REQUEST=$(echo "$line" | cut -d ' ' -f2)
				echo $TYPE $REQUEST 
			elif [ "x$line" = x ]
			then
				HTTP_200='HTTP/1.1 200 OK'
				HTTP_LOCATION='Location:'
				CONTENT_TYPE='Content-Type: application/json'
				HTTP_404='HTTP/1.1 404 Not Found'
				if echo $REQUEST | grep -qE '^/mock'
				then
					REQUEST=$(echo $REQUEST | sed 's/\/mock//g')
					if echo $REQUEST | grep -qE '^/echo/'
					then
						echo -e "Response:";
						echo -e "{\"message\":\"${REQUEST#"/echo/"}\"}";
						printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"message\":\"${REQUEST#"/echo/"}\"}" > .out
					elif echo $REQUEST | grep -qE '^/date'
					then
						echo -e "Response:";
						echo -e "{\"date\":\"$(date | xargs)\"}";
						printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"date\":\"$(date | xargs)\"}" > .out
					elif echo $REQUEST | grep -qE '^/services'
					then
						echo -e "Response:";
						echo -e "{\"services\":\"$(ls services | xargs)\"}";
						printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"services\":\"$(ls services | xargs)\"}" > .out
					elif echo $REQUEST | grep -qE '^/newservice'
					then
						# TODO Fazer um criador de servicos
						NEWSERVICE='new';
						if [ ! -e services/$NEWSERVICE ]; then							
							mkdir services/$NEWSERVICE;
							cat templates/json > services/$NEWSERVICE/GET;
							cat templates/json > services/$NEWSERVICE/POST;
							cat templates/json > services/$NEWSERVICE/PUT;
							cat templates/json > services/$NEWSERVICE/DELETE;
							echo -e "Response:";
							echo -e "{\"message\":\"Service $NEWSERVICE was created successfully.\"}";
							printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"message\":\"Service $NEWSERVICE was created successfully.\"}" > .out
						else
							echo -e "Response:";
							echo -e "{\"message\":\"Service $NEWSERVICE already exists.\"}";
							printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"message\":\"Service $NEWSERVICE already exists.\"}" > .out
						fi
					elif [ -e "services/$REQUEST/$TYPE" ]
					then
						echo -e "Response:";
						echo -e $(cat services/$REQUEST/$TYPE);
						printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_200" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST $(cat services/$REQUEST/$TYPE) > .out
					else
						echo -e "Response:";
						echo -e "{\"message\":\"Resource $REQUEST NOT FOUND!\"}";
						printf "%s\n%s\n%s\n%s\n\n%s\n" "$HTTP_404" "$HTTP_LOCATION" "$CONTENT_TYPE" $REQUEST "{\"message\":\"Resource $REQUEST NOT FOUND!\"}" > .out
					fi
				fi
			fi
		done
		echo -e "##################################################\n"
	)
done

